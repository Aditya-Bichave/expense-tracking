// lib/features/income/domain/repositories/income_repository.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
// --- Import Model instead of Entity ---
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

abstract class IncomeRepository {
  // --- MODIFIED Return Type ---
  Future<Either<Failure, List<IncomeModel>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Filter by Category ID
    String? accountId,
  });
  // --- END MODIFIED ---

  // Keep Add/Update returning Entity for now
  Future<Either<Failure, Income>> addIncome(Income income);
  Future<Either<Failure, Income>> updateIncome(Income income);

  Future<Either<Failure, void>> deleteIncome(String id);
  Future<Either<Failure, double>> getTotalIncomeForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate});
  Future<Either<Failure, void>> updateIncomeCategorization(String incomeId,
      String? categoryId, CategorizationStatus status, double? confidenceScore);
  Future<Either<Failure, int>> reassignIncomesCategory(
      String oldCategoryId, String newCategoryId);
}
