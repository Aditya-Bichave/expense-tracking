import 'package:hive_ce/hive.dart';

part 'sync_mutation_model.g.dart';

@HiveType(typeId: 23) // OpType
enum OpType {
  @HiveField(0)
  create,
  @HiveField(1)
  update,
  @HiveField(2)
  delete,
}

@HiveType(typeId: 22) // SyncStatus
enum SyncStatus {
  @HiveField(0)
  pending,
  @HiveField(1)
  sent,
  @HiveField(2)
  failed,
}

@HiveType(typeId: 12)
class SyncMutationModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String table; // e.g., 'groups'

  @HiveField(2)
  final OpType operation; // 'INSERT', 'UPDATE', 'DELETE' via Enum

  @HiveField(3)
  final Map<String, dynamic> payload; // JSON payload

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  int retryCount;

  @HiveField(6)
  SyncStatus status;

  @HiveField(7)
  String? lastError;

  SyncMutationModel({
    required this.id,
    required this.table,
    required this.operation,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.status = SyncStatus.pending,
    this.lastError,
  });
}
