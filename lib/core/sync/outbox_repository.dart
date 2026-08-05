import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:hive_ce/hive.dart';

class OutboxRepository {
  final Box<SyncMutationModel> _box;

  OutboxRepository(this._box);

  Future<void> add(SyncMutationModel item) async {
    await _box.add(item);
  }

  List<SyncMutationModel> getPendingItems() {
    // ⚡ Bolt Performance Optimization
    // Problem: `.where().toList()` creates an intermediate iterable.
    // Solution: Use a list comprehension to build the list directly.
    // Impact: Reduces garbage collection overhead.
    return [
      for (final item in _box.values)
        if (item.status == SyncStatus.pending ||
            item.status == SyncStatus.failed)
          item,
    ]..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> markAsSent(SyncMutationModel item) async {
    // Directly delete as it's processed
    await item.delete();
  }

  Future<void> markAsFailed(SyncMutationModel item, String error) async {
    item.status = SyncStatus.failed;
    item.lastError = error;
    item.retryCount++;
    await item.save();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
