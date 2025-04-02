import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

abstract class IncomeRepository {
  Future<Either<Failure, List<Income>>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountId, // Filter by account
  });
  Future<Either<Failure, Income>> addIncome(Income income);
  Future<Either<Failure, Income>> updateIncome(Income income);
  Future<Either<Failure, void>> deleteIncome(String id);
  Future<Either<Failure, double>> getTotalIncomeForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate}); // For balance calculation
  // Add GetIncomeSummary equivalent later if needed
}
