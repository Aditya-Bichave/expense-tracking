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
    // Problem: `where(...).toList()` iterates the entire list and creates an intermediate iterable.
    // Solution: Use a direct Dart list comprehension to filter and convert to a list in a single pass.
    // Impact: Reduces garbage collection pressure and memory allocations when getting pending items.
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
