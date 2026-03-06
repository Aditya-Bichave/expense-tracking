// coverage:ignore-file
import 'package:expense_tracker/core/sync/models/dead_letter_model.dart';
import 'package:hive_ce/hive.dart';

class DeadLetterRepository {
  final Box<DeadLetterModel> _box;

  DeadLetterRepository(this._box);

  Future<void> add(DeadLetterModel item) async {
    await _box.add(item);
  }

  List<DeadLetterModel> getItems() {
    return _box.values.toList()
      ..sort((a, b) => a.failedAt.compareTo(b.failedAt));
  }

  Future<void> deleteItem(DeadLetterModel item) async {
    await item.delete();
  }

  Future<void> clear() async {
    await _box.clear();
  }
}
