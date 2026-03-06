// coverage:ignore-file
// ignore_for_file: coverage:ignore-file
import 'dart:io';
import 'dart:async';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/dead_letter_repository.dart';
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncServiceStatus { synced, syncing, offline, error }

class SyncService {
  final SupabaseClient _client;
  final OutboxRepository _outboxRepository;
  final DeadLetterRepository _deadLetterRepository;
  final Connectivity _connectivity;
  final Box<GroupModel> _groupBox;
  final Box<GroupMemberModel> _groupMemberBox;

  final _statusController = StreamController<SyncServiceStatus>.broadcast();
  Stream<SyncServiceStatus> get statusStream => _statusController.stream;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  RealtimeChannel? _groupsChannel;
  RealtimeChannel? _groupMembersChannel;

  bool _isSyncing = false;
  static const int _maxRetries = 5;

  SyncService(
    this._client,
    this._outboxRepository,
    this._deadLetterRepository,
    this._connectivity,
    this._groupBox,
    this._groupMemberBox,
  ) {
    _safeAddStatus(SyncServiceStatus.synced);
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      result,
    ) {
      if (result.contains(ConnectivityResult.none)) {
        _safeAddStatus(SyncServiceStatus.offline);
      } else {
        // Online: Do not emit 'synced' here to avoid flicker.
        // processOutbox will emit 'syncing' then 'synced'/'error'.
        unawaited(processOutbox());
      }
    });
  }

  Future<void> initializeRealtime() async {
    try {
      if (_groupsChannel == null) {
        _groupsChannel = _client.channel('public:groups');
        _groupsChannel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'groups',
              callback: (payload) {
                log.info('Realtime update for groups: ${payload.eventType}');
                _handleGroupChange(payload);
              },
            )
            .subscribe();
      }

      if (_groupMembersChannel == null) {
        _groupMembersChannel = _client.channel('public:group_members');
        _groupMembersChannel!
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'group_members',
              callback: (payload) {
                log.info(
                  'Realtime update for group_members: ${payload.eventType}',
                );
                _handleGroupMemberChange(payload);
              },
            )
            .subscribe();
      }
    } catch (e) {
      log.severe('Failed to initialize realtime: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    if (_groupsChannel != null) {
      _client.removeChannel(_groupsChannel!);
      _groupsChannel = null;
    }
    if (_groupMembersChannel != null) {
      _client.removeChannel(_groupMembersChannel!);
      _groupMembersChannel = null;
    }
  }

  void _handleGroupChange(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = payload.oldRecord['id'];
        if (id == null || id is! String || id.isEmpty) {
          log.warning('Received delete event with invalid ID: $id');
          return;
        }
        _groupBox.delete(id);
        return;
      }

      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final serverGroup = GroupModel.fromJson(newRecord);
      final localGroup = _groupBox.get(serverGroup.id);

      if (localGroup == null) {
        _groupBox.put(serverGroup.id, serverGroup);
      } else {
        if (serverGroup.updatedAt.isAfter(localGroup.updatedAt)) {
          _groupBox.put(serverGroup.id, serverGroup);
        }
      }
    } catch (e) {
      log.severe('Error handling group realtime payload: $e');
    }
  }

  void _handleGroupMemberChange(PostgresChangePayload payload) {
    try {
      if (payload.eventType == PostgresChangeEvent.delete) {
        final id = payload.oldRecord['id'];
        if (id == null || id is! String || id.isEmpty) {
          log.warning('Received delete event with invalid ID: $id');
          return;
        }
        _groupMemberBox.delete(id);
        return;
      }

      final newRecord = payload.newRecord;
      if (newRecord.isEmpty) return;

      final serverMember = GroupMemberModel.fromJson(newRecord);
      final localMember = _groupMemberBox.get(serverMember.id);

      if (localMember == null) {
        _groupMemberBox.put(serverMember.id, serverMember);
        unawaited(_ensureGroupExists(serverMember.groupId));
      } else {
        // Last-Write-Wins check for member
        if (serverMember.updatedAt.isAfter(localMember.updatedAt)) {
          _groupMemberBox.put(serverMember.id, serverMember);
        } else {
          log.info('Ignoring stale update for group member ${serverMember.id}');
        }
      }
    } catch (e) {
      log.severe('Error handling group member realtime payload: $e');
    }
  }

  Future<void> _ensureGroupExists(String groupId) async {
    if (!_groupBox.containsKey(groupId)) {
      try {
        log.info('Fetching missing group $groupId for new member...');
        final groupData = await _client
            .from('groups')
            .select()
            .eq('id', groupId)
            .single();
        final group = GroupModel.fromJson(groupData);
        await _groupBox.put(group.id, group);
      } catch (e) {
        log.warning('Failed to fetch missing group $groupId: $e');
      }
    }
  }

  Future<void> processOutbox() async {
    if (_isSyncing) return;
    if (_statusController.isClosed) return;
    _isSyncing = true;
    _safeAddStatus(SyncServiceStatus.syncing);
    bool hadError = false;

    try {
      final pendingItems = _outboxRepository.getPendingItems();
      if (pendingItems.isEmpty) {
        _safeAddStatus(SyncServiceStatus.synced);
        return;
      }

      log.info('Syncing ${pendingItems.length} items...');

      for (final item in pendingItems) {
        if (item.retryCount >= _maxRetries) {
          await _deadLetterRepository.add(
            DeadLetterModel.fromSyncMutation(
              item..lastError = 'Max retries exceeded.',
            ),
          );
          await _outboxRepository.markAsSent(item); // Remove from outbox
          // Treated as processed (failed permanently), so effectively "synced" regarding queue blocking,
          // but arguably an error state. For now, following established pattern of continuing.
          continue;
        }

        try {
          await _processItem(item);
          await _outboxRepository.markAsSent(item);
        } catch (e) {
          log.warning('Failed to sync item ${item.id}: $e');
          final isNonRecoverable =
              e.toString().contains('PGRST') ||
              e.toString().contains('schema') ||
              e.toString().contains('CONFLICT');
          if (isNonRecoverable) {
            log.severe(
              'Non-recoverable error for item ${item.id}. Moving to dead letter queue.',
            );
            await _deadLetterRepository.add(
              DeadLetterModel.fromSyncMutation(item..lastError = e.toString()),
            );
            await _outboxRepository.markAsSent(item); // Remove from outbox
          } else {
            await _outboxRepository.markAsFailed(item, e.toString());
            hadError = true;
          }
        }
      }

      // Check queue status logic
      if (hadError) {
        _safeAddStatus(SyncServiceStatus.error);
      } else {
        // Double check if anything remains pending
        if (_outboxRepository
            .getPendingItems()
            .where((i) => i.status == SyncStatus.pending)
            .isEmpty) {
          _safeAddStatus(SyncServiceStatus.synced);
        }
      }
    } catch (e) {
      _safeAddStatus(SyncServiceStatus.error);
    } finally {
      _isSyncing = false;
    }
  }

  void _safeAddStatus(SyncServiceStatus status) {
    if (!_statusController.isClosed) {
      _statusController.add(status);
    }
  }

  Future<void> _processItem(SyncMutationModel item) async {
    final table = item.table;
    var payload = Map<String, dynamic>.from(item.payload);

    // 1. Handle Receipt Upload if needed
    if (payload.containsKey('x_local_receipt_path')) {
      final localPath = payload['x_local_receipt_path'];
      if (localPath != null && localPath is String) {
        log.info('Uploading offline receipt: $localPath');
        final txnId = payload['p_client_generated_id'] ?? item.id;
        final groupId = payload['p_group_id'];
        try {
          final fileExt = localPath.split('.').last;
          // Use transaction ID from payload if available, else random

          final fileName = '$txnId.$fileExt';

          final pathPrefix = groupId != null ? '$groupId/' : 'personal/';
          final uploadPath = '$pathPrefix$fileName';

          // Upload
          // Requires dart:io, but this is a service so it's fine.
          // Note: File class is not imported, assuming we can add import or use a helper.
          // Since we can't easily add import via search/replace, we'll try to use a helper
          // or assume file path is valid for Supabase upload if it supports path.
          // Supabase flutter upload takes File object.
          // We need to import dart:io.
          // Let's assume the surrounding code handles File or use a dynamic approach.
          // Actually, we need to modify imports to include dart:io.
          // But first, let's just do the logic.

          await _client.storage
              .from('receipts')
              .upload(
                uploadPath,
                File(localPath),
                fileOptions: const FileOptions(upsert: true),
              );
          final publicUrl = _client.storage
              .from('receipts')
              .getPublicUrl(uploadPath);
          payload['p_receipt_url'] = publicUrl;
        } catch (e) {
          log.warning(
            'Failed to upload receipt: $e. Queuing receipt upload for later.',
          );
          final updatePayload = {
            'x_local_receipt_path': localPath,
            'p_client_generated_id': txnId,
            'p_group_id': groupId,
          };
          final receiptMutation = SyncMutationModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            table: 'receipt_upload_queue',
            operation: OpType.update,
            payload: updatePayload,
            createdAt: DateTime.now(),
          );
          await _outboxRepository.add(receiptMutation);
        }
      }
      // Remove the local-only key before sending to Supabase
      payload.remove('x_local_receipt_path');
    }

    if (table == 'receipt_upload_queue') {
      final localPath = payload['x_local_receipt_path'];
      final txnId = payload['p_client_generated_id'];
      final groupId = payload['p_group_id'];
      final fileExt = localPath.split('.').last;
      final fileName = '$txnId.$fileExt';
      final pathPrefix = groupId != null ? '$groupId/' : 'personal/';
      final uploadPath = '$pathPrefix$fileName';

      await _client.storage
          .from('receipts')
          .upload(
            uploadPath,
            File(localPath),
            fileOptions: const FileOptions(upsert: true),
          );
      final publicUrl = _client.storage
          .from('receipts')
          .getPublicUrl(uploadPath);

      // Update the expense row directly since it should exist by now
      await _client
          .from('expenses')
          .update({'receipt_url': publicUrl})
          .eq('client_generated_id', txnId);
      return;
    }

    switch (item.operation) {
      case OpType.create:
        await _client.from(table).upsert(payload);
        break;
      case OpType.update:
        // Optimistic concurrency check
        if (payload.containsKey('revision')) {
          final expectedRevision = payload['revision'];
          final serverData = await _client
              .from(table)
              .select('revision')
              .eq('id', item.id)
              .maybeSingle();
          if (serverData != null) {
            final serverRevision = serverData['revision'] as int;
            if (serverRevision > expectedRevision) {
              log.warning(
                'Conflict detected for $table:${item.id}. Server revision: $serverRevision, Local revision: $expectedRevision',
              );
              throw Exception(
                'CONFLICT: Server version is newer. Please resolve manually.',
              );
            }
          }
        }

        final response = await _client
            .from(table)
            .update(payload)
            .eq('id', item.id)
            .select();
        // Check if any rows were actually updated
        if (response.isEmpty) {
          // If no rows updated, it might mean the record was deleted on server or doesn't exist yet.
          // Try upsert as fallback to ensure consistency.
          log.info(
            'Update for $table:${item.id} affected 0 rows. Attempting upsert fallback.',
          );
          await _client.from(table).upsert(payload);
        }
        break;
      case OpType.delete:
        await _client.from(table).delete().eq('id', item.id);
        break;
    }
  }
}
