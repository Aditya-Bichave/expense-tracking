import 'package:hive/hive.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/core/error/failure.dart'; // Use CacheFailure

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpenses();
  Future<ExpenseModel> addExpense(ExpenseModel expense);
  Future<ExpenseModel> updateExpense(ExpenseModel expense);
  Future<void> deleteExpense(String id);
  Future<void> clearAll(); // Optional: For testing or reset
}

class HiveExpenseLocalDataSource implements ExpenseLocalDataSource {
  final Box<ExpenseModel> expenseBox;

  HiveExpenseLocalDataSource(this.expenseBox);

  @override
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    try {
      // Ensure the model passed in has the accountId populated
      await expenseBox.put(expense.id, expense);
      return expense;
    } catch (e) {
      throw CacheFailure('Failed to add expense to cache: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    try {
      await expenseBox.delete(id);
    } catch (e) {
      throw CacheFailure(
          'Failed to delete expense from cache: ${e.toString()}');
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenses() async {
    try {
      return expenseBox.values.toList();
    } catch (e) {
      throw CacheFailure('Failed to get expenses from cache: ${e.toString()}');
    }
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    try {
      // Ensure the model passed in has the accountId populated
      await expenseBox.put(expense.id, expense);
      return expense;
    } catch (e) {
      throw CacheFailure('Failed to update expense in cache: ${e.toString()}');
    }
  }

  @override
  Future<void> clearAll() async {
    try {
      await expenseBox.clear();
    } catch (e) {
      throw CacheFailure('Failed to clear cache: ${e.toString()}');
    }
  }
}
