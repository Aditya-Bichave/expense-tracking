import 'dart:convert';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class SyncService {
  final SupabaseClient _client;
  final OutboxRepository _outboxRepository;
  bool _isSyncing = false;

  SyncService(this._client, this._outboxRepository);

  Future<void> processOutbox() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final pendingItems = _outboxRepository.getPendingItems();
      if (pendingItems.isEmpty) return;

      log.info('Syncing ${pendingItems.length} items...');

      for (final item in pendingItems) {
        try {
          await _processItem(item);
          await _outboxRepository.markAsSent(item);
        } catch (e) {
          log.warning('Failed to sync item ${item.id}: $e');
          await _outboxRepository.markAsFailed(item, e.toString());
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _processItem(OutboxItem item) async {
    final table = _getTableName(item.entityType);
    final payload = jsonDecode(item.payloadJson) as Map<String, dynamic>;

    // Use entityId for updates/deletes, not the OutboxItem ID
    final entityId = item.entityId;

    switch (item.opType) {
      case OpType.create:
        await _client.from(table).insert(payload);
        break;
      case OpType.update:
        await _client.from(table).update(payload).eq('id', entityId);
        break;
      case OpType.delete:
        await _client.from(table).delete().eq('id', entityId);
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
        return 'expenses'; // Group expenses are in 'expenses' table
      case EntityType.settlement:
        return 'settlements';
      case EntityType.invite:
        return 'invites';
      case EntityType.expense:
        return 'expenses'; // Personal expenses (if we unify them later)
      case EntityType.income:
        return 'income';
      case EntityType.category:
        return 'categories';
      case EntityType.budget:
        return 'budgets';
      case EntityType.goal:
        return 'goals';
      case EntityType.contribution:
        return 'goal_contributions';
      case EntityType.recurringRule:
        return 'recurring_rules';
    }
  }
}
