import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // ADDED

abstract class ExpenseRepository {
  Future<Either<Failure, List<Expense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Note: Filtering might now use category ID
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

  // --- ADDED METHOD ---
  /// Updates only the categorization details of an expense.
  Future<Either<Failure, void>> updateExpenseCategorization(
      String expenseId,
      String? categoryId, // Nullable if setting to uncategorized explicitly
      CategorizationStatus status,
      double? confidenceScore);
  // --- END ADDED METHOD ---
}
