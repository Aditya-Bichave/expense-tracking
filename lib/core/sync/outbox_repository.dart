import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:hive_ce/hive.dart';

class OutboxRepository {
  final Box<SyncMutationModel> _box;

  OutboxRepository(this._box);

  Future<void> add(SyncMutationModel item) async {
    await _box.add(item);
  }

  List<SyncMutationModel> getPendingItems() {
    return _box.values.where((item) {
      return item.status == SyncStatus.pending ||
          item.status == SyncStatus.failed;
    }).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> markAsSent(SyncMutationModel item) async {
    // Directly delete as it's processed
    await item.delete();
  }

  Future<void> markAsFailed(
    SyncMutationModel item,
    String error,
  ) async {
    item.status = SyncStatus.failed;
    item.lastError = error;
    item.retryCount++;
    await item.save();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
