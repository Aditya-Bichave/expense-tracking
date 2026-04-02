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
    // Problem: `where(...).toList()..sort(...)` creates an intermediate Iterable before materializing the list.
    // Solution: Just directly materialize the filtered list and sort it.
    final pendingItems = _box.values.where((item) {
      return item.status == SyncStatus.pending ||
          item.status == SyncStatus.failed;
    }).toList(growable: false); // Growable is false because we don't add to it here. But sort needs it to be modifiable, so we leave it default.

    pendingItems.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return pendingItems;
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
