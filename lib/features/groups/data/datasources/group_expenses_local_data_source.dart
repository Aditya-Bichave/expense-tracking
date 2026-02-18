import 'package:expense_tracker/features/groups/data/models/group_expense_model.dart';
import 'package:hive_ce/hive.dart';

abstract class GroupExpensesLocalDataSource {
  Future<void> cacheExpenses(List<GroupExpenseModel> expenses);
  Future<void> addExpense(GroupExpenseModel expense);
  List<GroupExpenseModel> getExpensesForGroup(String groupId);
}

class GroupExpensesLocalDataSourceImpl implements GroupExpensesLocalDataSource {
  final Box<GroupExpenseModel> _box;

  GroupExpensesLocalDataSourceImpl(this._box);

  @override
  Future<void> cacheExpenses(List<GroupExpenseModel> expenses) async {
    final Map<String, GroupExpenseModel> map = {
      for (var e in expenses) e.id: e,
    };
    await _box.putAll(map);
  }

  @override
  Future<void> addExpense(GroupExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  @override
  List<GroupExpenseModel> getExpensesForGroup(String groupId) {
    return _box.values.where((e) => e.groupId == groupId).toList()
      ..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
  }
}
