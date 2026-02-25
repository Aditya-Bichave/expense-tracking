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

class SyncService {
  final SupabaseClient _client;
  final OutboxRepository _outboxRepository;
  final Connectivity _connectivity;
  final Box<GroupModel> _groupBox;
  final Box<GroupMemberModel> _groupMemberBox;

  final _statusController = StreamController<SyncServiceStatus>.broadcast();
  Stream<SyncServiceStatus> get statusStream => _statusController.stream;

  final _errorController = StreamController<String>.broadcast();
  Stream<String> get errorStream => _errorController.stream;

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
          processOutbox().catchError((e) {
            log.severe("Background sync failed: $e");
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
    } catch (e) {
      log.severe('Failed to initialize realtime: $e');
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    _errorController.close();
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
        unawaited(
          _ensureGroupExists(serverMember.groupId).catchError((e) {
            log.warning('Failed to ensure group exists via realtime: $e');
          }),
        );
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
          final errorMsg =
              'Max retries exceeded for item ${item.id}. Last error: ${item.lastError}';
          await _outboxRepository.markAsFailed(item, 'Max retries exceeded.');

          if (!_errorController.isClosed) {
            _errorController.add(errorMsg);
          }
          log.severe(errorMsg);
          // Treated as processed (failed permanently), so effectively "synced" regarding queue blocking
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
      log.severe("ProcessOutbox critical error: $e");
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
    final payload = item.payload;

    switch (item.operation) {
      case OpType.create:
        await _client.from(table).upsert(payload);
        break;
      case OpType.update:
        await _client.from(table).update(payload).eq('id', item.id);
        break;
      case OpType.delete:
        await _client.from(table).delete().eq('id', item.id);
        break;
    }
  }
}
