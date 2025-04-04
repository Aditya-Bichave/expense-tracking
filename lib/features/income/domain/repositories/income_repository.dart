// lib/features/income/domain/repositories/income_repository.dart
// MODIFIED FILE
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/enums.dart';

abstract class IncomeRepository {
  Future<Either<Failure, List<Income>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Note: This filter might need to use ID now
    String? accountId,
  });
  Future<Either<Failure, Income>> addIncome(Income income);
  Future<Either<Failure, Income>> updateIncome(Income income);
  Future<Either<Failure, void>> deleteIncome(String id);
  Future<Either<Failure, double>> getTotalIncomeForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate});

  /// Updates only the categorization details of an income record.
  Future<Either<Failure, void>> updateIncomeCategorization(
      String incomeId,
      String? categoryId, // Nullable if setting to uncategorized explicitly
      CategorizationStatus status,
      double? confidenceScore);

  // --- ADDED METHOD ---
  /// Reassigns incomes from one category to another in bulk.
  /// Sets status to 'categorized' and clears confidence.
  Future<Either<Failure, int>> reassignIncomesCategory(
      String oldCategoryId, String newCategoryId // Typically 'uncategorized' ID
      );
  // --- END ADDED ---
}
