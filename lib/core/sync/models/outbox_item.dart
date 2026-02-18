import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';

part 'outbox_item.g.dart';

@HiveType(typeId: 12)
class OutboxItem extends HiveObject {
  @HiveField(0)
  final String id; // UUID of the item itself (optional, but good for tracking)

  @HiveField(1)
  final EntityType entityType;

  @HiveField(2)
  final OpType opType;

  @HiveField(3)
  final String payloadJson; // Serialized JSON of the entity or changes

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  String status; // 'pending', 'processing', 'sent', 'failed'

  @HiveField(7)
  String? lastError;

  @HiveField(8)
  final String entityId; // The ID of the actual entity being synced

  OutboxItem({
    required this.id,
    required this.entityType,
    required this.opType,
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.status = 'pending',
    this.lastError,
    required this.entityId,
  });
}
