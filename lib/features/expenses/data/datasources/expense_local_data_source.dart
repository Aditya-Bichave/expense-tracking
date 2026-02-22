import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/utils/logger.dart';

abstract class ExpenseLocalDataSource {
  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  });
  Future<ExpenseModel?> getExpenseById(String id); // ADDED: Return nullable
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
  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    try {
      final List<ExpenseModel> results = [];

      final accountIdSet = (accountId != null && accountId.isNotEmpty)
          ? accountId.split(',').toSet()
          : null;
      final categoryIdSet = (categoryId != null && categoryId.isNotEmpty)
          ? categoryId.split(',').toSet()
          : null;

      // Optimize: Calculate date boundaries once outside the loop
      final startDateOnly = startDate != null
          ? DateTime(startDate.year, startDate.month, startDate.day)
          : null;
      final endDateInclusive = endDate != null
          ? DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59)
          : null;

      for (final expense in expenseBox.values) {
        if (startDateOnly != null) {
          // Compare directly: expense.date >= startDate (normalized to midnight)
          if (expense.date.isBefore(startDateOnly)) continue;
        }
        if (endDateInclusive != null) {
          // Compare directly: expense.date <= endDate (normalized to end of day)
          if (expense.date.isAfter(endDateInclusive)) continue;
        }
        if (accountIdSet != null && !accountIdSet.contains(expense.accountId)) {
          continue;
        }
        if (categoryIdSet != null &&
            !categoryIdSet.contains(expense.categoryId)) {
          continue;
        }
        results.add(expense);
      }
      log.info(
        "Retrieved ${results.length} expenses from Hive after applying filters.",
      );
      return results;
    } catch (e, s) {
      log.severe("Failed to get expenses from cache$e$s");
      throw CacheFailure('Failed to get expenses: ${e.toString()}');
    }
  }

  // --- ADDED IMPLEMENTATION ---
  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    try {
      final expense = expenseBox.get(id);
      if (expense != null) {
        log.fine("Retrieved expense by ID $id from Hive.");
      } else {
        log.warning("Expense with ID $id not found in Hive.");
      }
      return expense; // Returns null if not found
    } catch (e, s) {
      log.severe("Failed to get expense by ID $id from cache$e$s");
      throw CacheFailure('Failed to get expense by ID: ${e.toString()}');
    }
  }
  // --- END ADDED ---

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    // Ensure the expense exists before updating
    if (!expenseBox.containsKey(expense.id)) {
      log.warning("Attempted to update non-existent expense ID: ${expense.id}");
      throw CacheFailure("Expense with ID ${expense.id} not found for update.");
    }
    try {
      await expenseBox.put(expense.id, expense);
      log.info(
        "Updated expense '${expense.title}' (ID: ${expense.id}) in Hive.",
      );
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
