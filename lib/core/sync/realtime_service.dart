import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class RealtimeService {
  final SupabaseClient _client;
  RealtimeChannel? _channel;
  final StreamController<PostgresChangePayload> _changesController =
      StreamController.broadcast();

  RealtimeService(this._client);

  Stream<PostgresChangePayload> get changes => _changesController.stream;

  void subscribeToGroup(String groupId) {
    if (_channel != null) {
      _client.removeChannel(_channel!);
    }

    _channel = _client
        .channel('group_$groupId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'expenses',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'group_id',
            value: groupId,
          ),
          callback: (payload) {
            _changesController.add(payload);
          },
        )
        .subscribe();

    log.info('Subscribed to realtime channel for group $groupId');
  }

  void unsubscribe() {
    if (_channel != null) {
      _client.removeChannel(_channel!);
      _channel = null;
    }
  }

  void dispose() {
    unsubscribe();
    _changesController.close();
  }
}
