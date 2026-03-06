import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';

part 'dead_letter_model.g.dart';

@HiveType(typeId: 24)
class DeadLetterModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String table;

  @HiveField(2)
  final OpType operation;

  @HiveField(3)
  final Map<String, dynamic> payload;

  @HiveField(4)
  final DateTime createdAt;

  @HiveField(5)
  final DateTime failedAt;

  @HiveField(6)
  final String lastError;

  @HiveField(7)
  final int retryCount;

  DeadLetterModel({
    required this.id,
    required this.table,
    required this.operation,
    required this.payload,
    required this.createdAt,
    required this.failedAt,
    required this.lastError,
    required this.retryCount,
  });

  factory DeadLetterModel.fromSyncMutation(SyncMutationModel mutation) {
    return DeadLetterModel(
      id: mutation.id,
      table: mutation.table,
      operation: mutation.operation,
      payload: mutation.payload,
      createdAt: mutation.createdAt,
      failedAt: DateTime.now(),
      lastError: mutation.lastError ?? 'Unknown error',
      retryCount: mutation.retryCount,
    );
  }

  SyncMutationModel toSyncMutation() {
    return SyncMutationModel(
      id: id,
      table: table,
      operation: operation,
      payload: payload,
      createdAt: createdAt,
      retryCount: 0,
      status: SyncStatus.pending,
      lastError: null,
    );
  }
}
