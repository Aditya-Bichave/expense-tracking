import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:hive_ce/hive.dart';

class OutboxRepository {
  final Box<OutboxItem> _box;

  OutboxRepository(this._box);

  Future<void> add(OutboxItem item) async {
    await _box.add(item);
  }

  List<OutboxItem> getPendingItems() {
    final now = DateTime.now();
    return _box.values.where((item) {
      final isPending = item.status == OutboxStatus.pending;
      final isFailedAndReady =
          item.status == OutboxStatus.failed &&
          (item.nextRetryAt == null || item.nextRetryAt!.isBefore(now));

      return isPending || isFailedAndReady;
    }).toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  Future<void> markAsSent(OutboxItem item) async {
    item.status = OutboxStatus.sent;
    await item.save();
    await item.delete();
  }

  Future<void> markAsFailed(
    OutboxItem item,
    String error, {
    DateTime? nextRetryAt,
  }) async {
    item.status = OutboxStatus.failed;
    item.lastError = error;
    item.retryCount++;
    if (nextRetryAt != null) {
      item.nextRetryAt = nextRetryAt;
    }
    await item.save();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
