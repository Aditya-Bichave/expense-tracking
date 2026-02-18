import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';

class RealtimeEvent {
  final EntityType entityType;
  final OpType opType;
  final Map<String, dynamic> payload;

  RealtimeEvent({
    required this.entityType,
    required this.opType,
    required this.payload,
  });
}
