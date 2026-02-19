import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:hive_ce/hive.dart';

class OutboxRepository {
  final Box<OutboxItem> _box;

  OutboxRepository(this._box);

  Future<void> add(OutboxItem item) async {
    await _box.add(item);
  }

  List<OutboxItem> getPendingItems() {
    return _box.values
        .where(
          (item) =>
              item.status == OutboxStatus.pending ||
              item.status == OutboxStatus.failed,
        )
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> markAsSent(OutboxItem item) async {
    item.status = OutboxStatus.sent;
    await item.save();
    await item.delete();
  }

  Future<void> markAsFailed(OutboxItem item, String error) async {
    item.status = OutboxStatus.failed;
    item.lastError = error;
    item.retryCount++;
    await item.save();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
