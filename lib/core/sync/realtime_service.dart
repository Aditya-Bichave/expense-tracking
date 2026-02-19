import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Fixed import location

class RealtimeService {
  final SupabaseClient _client;
  final GroupsLocalDataSource _groupsLocalDataSource;
  final GroupExpensesLocalDataSource _expensesLocalDataSource;
  RealtimeChannel? _channel;

  RealtimeService(
    this._client,
    this._groupsLocalDataSource,
    this._expensesLocalDataSource,
  );

  void subscribe() {
    if (_channel != null) return;

    log.info('Subscribing to Realtime changes...');

    _channel = _client
        .channel('public:all')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'groups',
          callback: _handleGroupChange,
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          callback: _handleExpenseChange,
        )
        .subscribe();
  }

  void unsubscribe() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
      log.info('Unsubscribed from Realtime changes.');
    }
  }

  Future<void> _handleGroupChange(PostgresChangePayload payload) async {
    log.info('Realtime Group Change: ${payload.eventType}');
    try {
      if (payload.eventType == PostgresChangeEvent.insert ||
          payload.eventType == PostgresChangeEvent.update) {
        final group = GroupModel.fromJson(payload.newRecord);
        await _groupsLocalDataSource.saveGroup(group);
        publishDataChangedEvent(
          type: DataChangeType.group,
          reason: DataChangeReason.remoteUpdate,
        );
      }
    } catch (e) {
      log.severe('Error handling realtime group change: $e');
    }
  }

  Future<void> _handleExpenseChange(PostgresChangePayload payload) async {
    log.info('Realtime Expense Change: ${payload.eventType}');
    try {
      if (payload.eventType == PostgresChangeEvent.insert ||
          payload.eventType == PostgresChangeEvent.update) {
        final expense = GroupExpenseModel.fromJson(payload.newRecord);
        await _expensesLocalDataSource.saveExpense(expense);
        publishDataChangedEvent(
          type: DataChangeType.expense,
          reason: DataChangeReason.remoteUpdate,
        );
      }
    } catch (e) {
      log.severe('Error handling realtime expense change: $e');
    }
  }
}
