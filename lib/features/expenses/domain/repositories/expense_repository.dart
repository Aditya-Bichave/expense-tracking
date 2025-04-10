// lib/features/expenses/domain/repositories/expense_repository.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
// --- Import Model instead of Entity ---
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';

abstract class ExpenseRepository {
  // --- MODIFIED Return Type ---
  Future<Either<Failure, List<ExpenseModel>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Filter by Category ID
    String? accountId,
  });
  // --- END MODIFIED ---

  // Add/Update still take Entity, but might return Model or hydrated Entity?
  // Let's keep them returning the hydrated Entity for consistency in Add/Edit flow for now.
  Future<Either<Failure, Expense>> addExpense(Expense expense);
  Future<Either<Failure, Expense>> updateExpense(Expense expense);

  Future<Either<Failure, void>> deleteExpense(String id);
  Future<Either<Failure, double>> getTotalExpensesForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary(
      {DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, void>> updateExpenseCategorization(String expenseId,
      String? categoryId, CategorizationStatus status, double? confidenceScore);
  Future<Either<Failure, int>> reassignExpensesCategory(
      String oldCategoryId, String newCategoryId);
}
