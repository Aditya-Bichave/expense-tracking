import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:hive_ce/hive.dart';

abstract class GroupExpensesLocalDataSource {
  Future<void> saveExpense(GroupExpenseModel expense);
  Future<void> saveExpenses(List<GroupExpenseModel> expenses);
  List<GroupExpenseModel> getExpenses(String groupId);
}

class GroupExpensesLocalDataSourceImpl implements GroupExpensesLocalDataSource {
  final Box<GroupExpenseModel> _box;

  GroupExpensesLocalDataSourceImpl(this._box);

  @override
  Future<void> saveExpense(GroupExpenseModel expense) async {
    await _box.put(expense.id, expense);
  }

  @override
  Future<void> saveExpenses(List<GroupExpenseModel> expenses) async {
    final map = {for (var e in expenses) e.id: e};
    await _box.putAll(map);
  }

  @override
  List<GroupExpenseModel> getExpenses(String groupId) {
    return _box.values.where((e) => e.groupId == groupId).toList();
  }
}
