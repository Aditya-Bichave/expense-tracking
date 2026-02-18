import 'dart:convert';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncService {
  final OutboxRepository _outboxRepository;
  final SupabaseClient _client;

  SyncService(this._outboxRepository)
      : _client = SupabaseClientProvider.client;

  bool _isSyncing = false;
  static const int maxRetries = 5;

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
        if (item.retryCount >= maxRetries) {
          log.warning("[SyncService] Item ${item.id} exceeded max retries. Marking failed.");
          item.status = 'failed';
          await item.save();
          continue;
        }

        try {
          item.status = 'processing';
          await item.save();

          await _syncItem(item);

          // Success - remove from outbox (or mark synced)
          await _outboxRepository.delete(item.id);
          log.info("[SyncService] Synced item ${item.id} successfully.");
        } catch (e, s) {
          log.severe("[SyncService] Failed to sync item ${item.id}: $e", e, s);
          item.retryCount++;
          item.lastError = e.toString();
          item.status = 'pending'; // Retry later
          await item.save();
        }
      }
    } catch (e) {
      log.severe("[SyncService] Error processing outbox: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncItem(OutboxItem item) async {
    final table = _getTableName(item.entityType);
    final data = jsonDecode(item.payloadJson) as Map<String, dynamic>;

    switch (item.opType) {
      case OpType.create:
        await _client.from(table).insert(data);
        break;
      case OpType.update:
        // Assume ID is in data or entityId
        await _client.from(table).update(data).eq('id', item.entityId);
        break;
      case OpType.delete:
        await _client.from(table).delete().eq('id', item.entityId);
        break;
    }
  }

  String _getTableName(EntityType type) {
    switch (type) {
      case EntityType.group:
        return 'groups';
      case EntityType.groupMember:
        return 'group_members';
      case EntityType.groupExpense:
        return 'expenses';
      case EntityType.settlement:
        return 'settlements';
      case EntityType.invite:
        return 'invites';
    }
  }
}
