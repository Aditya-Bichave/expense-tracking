import 'dart:io';
import 'dart:async';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

enum SyncServiceStatus { synced, syncing, offline, error }

// REQUIRES HUMAN REVIEW - DO NOT AUTO-MERGE
class SyncService {
  final SupabaseClient _client;
  final OutboxRepository _outboxRepository;
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
        unawaited(
          processOutbox().catchError((e, s) {
            log.severe("Failed to process outbox in background: $e\n$s");
          }),
        );
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
    } catch (e, s) {
      log.severe('Failed to initialize realtime: $e\n$s');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    if (_groupsChannel != null) {
      _client.removeChannel(_groupsChannel!);
    }
    if (_groupMembersChannel != null) {
      _client.removeChannel(_groupMembersChannel!);
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
          await _outboxRepository.markAsFailed(item, 'Max retries exceeded.');
          // Treated as processed (failed permanently), so effectively "synced" regarding queue blocking,
          // but arguably an error state. For now, following established pattern of continuing.
          continue;
        }

        try {
          await _processItem(item);
          await _outboxRepository.markAsSent(item);
        } catch (e) {
          log.warning('Failed to sync item ${item.id}: $e');
          await _outboxRepository.markAsFailed(item, e.toString());
          hadError = true;
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
    final payload = Map<String, dynamic>.from(item.payload);

    // 1. Handle Receipt Upload if needed
    if (payload.containsKey('x_local_receipt_path')) {
      final localPath = payload['x_local_receipt_path'];
      if (localPath != null && localPath is String) {
        log.info('Uploading offline receipt: $localPath');
        try {
          final fileExt = localPath.split('.').last;
          // Use transaction ID from payload if available, else random
          final txnId = payload['p_client_generated_id'] ?? item.id;
          final fileName = '$txnId.$fileExt';
          final groupId = payload['p_group_id'];
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
          payload['p_receipt_url'] = publicUrl;
        } catch (e, s) {
          log.warning(
            'Failed to upload receipt: $e. Continuing without it.\n$s',
          );
        }
      }
      // Remove the local-only key before sending to Supabase
      payload.remove('x_local_receipt_path');
    }

    if (table.startsWith('rpc/')) {
      final rpcName = table.substring(4);
      await _client.rpc(rpcName, params: payload);
      return;
    }

    switch (item.operation) {
      case OpType.create:
        await _client.from(table).insert(payload);
        break;
      case OpType.update:
        if (!payload.containsKey('id')) {
          throw Exception('Update missing ID');
        }
        await _client.from(table).update(payload).eq('id', payload['id']);
        break;
      case OpType.delete:
        if (!payload.containsKey('id')) {
          throw Exception('Delete missing ID');
        }
        await _client.from(table).delete().eq('id', payload['id']);
        break;
    }
  }

  // Realtime Handlers

  void _handleGroupChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      final data = payload.newRecord;
      if (data.containsKey('id')) {
        final group = GroupModel.fromJson(data);
        _groupBox.put(group.id, group);
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id'];
      if (id != null) {
        _groupBox.delete(id);
      }
    }
  }

  void _handleGroupMemberChange(PostgresChangePayload payload) {
    if (payload.eventType == PostgresChangeEvent.insert ||
        payload.eventType == PostgresChangeEvent.update) {
      final data = payload.newRecord;
      if (data.containsKey('id')) {
        final member = GroupMemberModel.fromJson(data);
        _groupMemberBox.put(member.id, member);
      }
    } else if (payload.eventType == PostgresChangeEvent.delete) {
      final id = payload.oldRecord['id'];
      if (id != null) {
        _groupMemberBox.delete(id);
      }
    }
  }
}
