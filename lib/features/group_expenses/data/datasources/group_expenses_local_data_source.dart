import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:hive_ce/hive.dart';

abstract class GroupExpensesLocalDataSource {
  Future<void> saveExpense(GroupExpenseModel expense);
  Future<void> saveExpenses(List<GroupExpenseModel> expenses);
  List<GroupExpenseModel> getExpenses(String groupId);
  Future<void> deleteExpense(String expenseId);
  Future<void> deleteExpensesForGroup(String groupId);
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
    // ⚡ Bolt Performance Optimization
    // Problem: `where(...).toList()` iterates the entire list and creates a sublist.
    // Solution: Iterate once directly, skipping the intermediate list allocation.
    // Impact: Reduces GC pressure when getting group expenses.
    final result = <GroupExpenseModel>[];
    for (final e in _box.values) {
      if (e.groupId == groupId) {
        result.add(e);
      }
    }
    return result;
  }

  @override
  Future<void> deleteExpense(String expenseId) async {
    await _box.delete(expenseId);
  }

  @override
  Future<void> deleteExpensesForGroup(String groupId) async {
    // ⚡ Bolt Performance Optimization
    // Problem: `where(...).map(...).toList()` iterates and allocates intermediate structures.
    // Solution: Iterate once directly with list comprehension.
    // Impact: Reduces GC pressure when deleting expenses for a group.
    final expenseIds = [
      for (final expense in _box.values)
        if (expense.groupId == groupId) expense.id,
    ];
    if (expenseIds.isEmpty) {
      return;
    }
    await _box.deleteAll(expenseIds);
  }
}
