import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';

class OutboxRepository {
  final Box<OutboxItem> _box;

  OutboxRepository(this._box);

  Future<void> add(OutboxItem item) async {
    await _box.put(item.id, item);
  }

  Future<void> update(OutboxItem item) async {
    await item.save();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
  }

  List<OutboxItem> getPendingItems() {
    return _box.values
        .where((item) => item.status == 'pending' || item.status == 'failed')
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }
}
