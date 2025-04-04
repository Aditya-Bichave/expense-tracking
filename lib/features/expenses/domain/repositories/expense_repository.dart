// lib/features/expenses/domain/repositories/expense_repository.dart
// MODIFIED FILE
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/core/utils/enums.dart';

abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Note: This filter might need to use ID now
    String? accountId,
  });
  Future<Either<Failure, Expense>> addExpense(Expense expense);
  Future<Either<Failure, Expense>> updateExpense(Expense expense);
  Future<Either<Failure, void>> deleteExpense(String id);
  Future<Either<Failure, double>> getTotalExpensesForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  });

  /// Updates only the categorization details of an expense.
  Future<Either<Failure, void>> updateExpenseCategorization(
      String expenseId,
      String? categoryId, // Nullable if setting to uncategorized explicitly
      CategorizationStatus status,
      double? confidenceScore);

  // --- ADDED METHOD ---
  /// Reassigns expenses from one category to another in bulk.
  /// Sets status to 'categorized' and clears confidence.
  Future<Either<Failure, int>> reassignExpensesCategory(
      String oldCategoryId, String newCategoryId // Typically 'uncategorized' ID
      );
  // --- END ADDED ---
}
