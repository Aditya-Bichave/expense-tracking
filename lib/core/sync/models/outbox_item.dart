import 'package:hive_ce/hive.dart';

part 'outbox_item.g.dart';

@HiveType(typeId: 20)
enum OutboxStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  sent,
  @HiveField(2)
  failed,
}

@HiveType(typeId: 21)
enum OpType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

@HiveType(typeId: 22)
enum EntityType {
  @HiveField(0)
  group,
  @HiveField(1)
  groupMember,
  @HiveField(2)
  groupExpense,
  @HiveField(3)
  settlement,
  @HiveField(4)
  invite,
  @HiveField(5)
  expense,
  @HiveField(6)
  income,
  @HiveField(7)
  category,
  @HiveField(8)
  budget,
  @HiveField(9)
  goal,
  @HiveField(10)
  contribution,
  @HiveField(11)
  recurringRule,
}

@HiveType(typeId: 12)
class OutboxItem extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final EntityType entityType;

  @HiveField(2)
  final OpType opType;

  @HiveField(3)
  final String payloadJson;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  OutboxStatus status;

  @HiveField(7)
  String? lastError;

  @HiveField(8)
  DateTime? nextRetryAt;

  @HiveField(9)
  final String entityId;

  OutboxItem({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.opType,
    required this.payloadJson,
    required this.createdAt,
    this.retryCount = 0,
    this.status = OutboxStatus.pending,
    this.lastError,
    this.nextRetryAt,
  });
}
