import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';
import 'package:expense_tracker/core/sync/models/realtime_event.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class RealtimeService {
  final SupabaseClient _client;
  final StreamController<RealtimeEvent> _eventController =
      StreamController.broadcast();

  RealtimeService() : _client = SupabaseClientProvider.client;

  Stream<RealtimeEvent> get events => _eventController.stream;

  List<RealtimeChannel> _channels = [];

  void start() {
    log.info("[RealtimeService] Starting subscriptions...");
    _subscribe('groups', EntityType.group);
    _subscribe('group_members', EntityType.groupMember);
    _subscribe('expenses', EntityType.groupExpense);
    _subscribe('settlements', EntityType.settlement);
    _subscribe('invites', EntityType.invite);
  }

  void stop() {
    for (var channel in _channels) {
      _client.removeChannel(channel);
    }
    _channels.clear();
  }

  void _subscribe(String table, EntityType entityType) {
    final channel = _client
        .channel('public:$table')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: table,
          callback: (payload) {
            final op = _mapOpType(payload.eventType);
            if (op == null) return;

            // payload.newRecord or payload.oldRecord depending on op
            final data = op == OpType.delete
                ? payload.oldRecord
                : payload.newRecord;

            if (data == null) return;

            _eventController.add(
              RealtimeEvent(entityType: entityType, opType: op, payload: data),
            );
          },
        )
        .subscribe();

    _channels.add(channel);
  }

  OpType? _mapOpType(PostgresChangeEvent type) {
    switch (type) {
      case PostgresChangeEvent.insert:
        return OpType.create;
      case PostgresChangeEvent.update:
        return OpType.update;
      case PostgresChangeEvent.delete:
        return OpType.delete;
      default:
        return null;
    }
  }
}
