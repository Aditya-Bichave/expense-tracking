import 'package:hive/hive.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Future<ExpenseModel> addExpense(ExpenseModel expense);
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<void> clearAll();
}

class HiveExpenseLocalDataSource implements ExpenseLocalDataSource {
  final Box<ExpenseModel> expenseBox;

  HiveExpenseLocalDataSource(this.expenseBox);

  @override
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      await expenseBox.put(expense.id, expense);
      log.info("Added expense '${expense.title}' (ID: ${expense.id}) to Hive.");
      return expense;
    } catch (e, s) {
      log.severe("Failed to add expense '${expense.title}' to cache$e$s");
      throw CacheFailure('Failed to add expense: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await expenseBox.delete(id);
      log.info("Deleted expense (ID: $id) from Hive.");
    } catch (e, s) {
      log.severe("Failed to delete expense (ID: $id) from cache$e$s");
      throw CacheFailure('Failed to delete expense: ${e.toString()}');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      final expenses = expenseBox.values.toList();
      log.info("Retrieved ${expenses.length} expenses from Hive.");
      return expenses;
    } catch (e, s) {
      log.severe("Failed to get expenses from cache$e$s");
      throw CacheFailure('Failed to get expenses: ${e.toString()}');
    }
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      await expenseBox.put(expense.id, expense);
      log.info(
          "Updated expense '${expense.title}' (ID: ${expense.id}) in Hive.");
      return expense;
    } catch (e, s) {
      log.severe("Failed to update expense '${expense.title}' in cache$e$s");
      throw CacheFailure('Failed to update expense: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      final count = await expenseBox.clear();
      log.info("Cleared expenses box in Hive ($count items removed).");
    } catch (e, s) {
      log.severe("Failed to clear expenses cache$e$s");
      throw CacheFailure('Failed to clear expenses cache: ${e.toString()}');
    }
  }
}
