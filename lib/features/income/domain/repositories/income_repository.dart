import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/core/utils/enums.dart'; // ADDED

abstract class IncomeRepository {
  Future<Either<Failure, List<Income>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Note: Filtering might now use category ID
    String? accountId, // Filter by account
  });
  Future<Either<Failure, Income>> addIncome(Income income);
  Future<Either<Failure, Income>> updateIncome(Income income);
  Future<Either<Failure, void>> deleteIncome(String id);
  Future<Either<Failure, double>> getTotalIncomeForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate}); // For balance calculation

  // --- ADDED METHOD ---
  /// Updates only the categorization details of an income record.
  Future<Either<Failure, void>> updateIncomeCategorization(
      String incomeId,
      String? categoryId, // Nullable if setting to uncategorized explicitly
      CategorizationStatus status,
      double? confidenceScore);
  // --- END ADDED METHOD ---

  // Add GetIncomeSummary equivalent later if needed
}
