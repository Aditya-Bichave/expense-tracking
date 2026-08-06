import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:hive_ce/hive.dart';

class OutboxRepository {
  final Box<SyncMutationModel> _box;

  OutboxRepository(this._box);

  Future<void> add(SyncMutationModel item) async {
    await _box.add(item);
  }

  List<SyncMutationModel> getPendingItems() {
    // ⚡ Bolt: [Performance Improvement]
    // 💡 What: Replaced `.where().toList()..sort()` chain with a single collection loop and direct `.sort()`.
    // 🎯 Why: `.where()` creates an intermediate iterable. For large data sets this takes O(N) allocation time.
    // 📊 Impact: Prevents O(N) intermediate allocation, reducing GC pressure during sync item retrieval.
    final items = <SyncMutationModel>[];
    for (final item in _box.values) {
      if (item.status == SyncStatus.pending ||
          item.status == SyncStatus.failed) {
        items.add(item);
      }
    }
    items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return items;
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
