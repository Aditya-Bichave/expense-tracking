import 'dart:async';
import 'dart:convert';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  final OutboxRepository _outboxRepository;
  final SupabaseClient _supabaseClient;
  bool _isSyncing = false;

  SyncService(this._outboxRepository, this._supabaseClient);

  Future<void> processOutbox() async {
    if (_isSyncing) return;
    _isSyncing = true;
    log.info("[SyncService] Starting outbox processing...");

    try {
      final pendingItems = _outboxRepository.getPendingItems();
      if (pendingItems.isEmpty) {
        log.info("[SyncService] No pending items.");
        _isSyncing = false;
        return;
      }

      for (final item in pendingItems) {
        try {
          await _syncItem(item);
          await _outboxRepository.delete(item.id);
        } catch (e, s) {
          log.severe("[SyncService] Failed to sync item ${item.id}: $e", e, s);
        }
      }
    } catch (e, s) {
      log.severe("[SyncService] Error processing outbox: $e", e, s);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItem(OutboxItem item) async {
    final payload = jsonDecode(item.payloadJson);
    final table = _getTableName(item.entityType);

    if (item.opType == OpType.create) {
      await _supabaseClient.from(table).insert(payload);
    } else if (item.opType == OpType.update) {
      await _supabaseClient.from(table).update(payload).eq('id', item.entityId);
    } else if (item.opType == OpType.delete) {
      await _supabaseClient.from(table).delete().eq('id', item.entityId);
    }
  }

  String _getTableName(EntityType type) {
    switch (type) {
      case EntityType.group: return 'groups';
      case EntityType.groupExpense: return 'expenses'; // Fixed enum case
      case EntityType.settlement: return 'settlements';
      case EntityType.groupMember: return 'group_members'; // Fixed enum case
      case EntityType.invite: return 'invites';
    }
  }
}
