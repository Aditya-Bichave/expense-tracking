import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class GetExpenseSummaryUseCase
    implements UseCase<ExpenseSummary, GetSummaryParams> {
  final ExpenseRepository repository;

  GetExpenseSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, ExpenseSummary>> call(GetSummaryParams params) async {
    log.info(
        "Executing GetExpenseSummaryUseCase. Start: ${params.startDate}, End: ${params.endDate}");
    // The summary logic is inside ExpenseRepositoryImpl
    final result = await repository.getExpenseSummary(
      startDate: params.startDate,
      endDate: params.endDate,
    );
    result.fold(
      (failure) =>
          log.warning("[GetExpenseSummaryUseCase] Failed: ${failure.message}"),
      (summary) => log.info(
          "[GetExpenseSummaryUseCase] Succeeded. Total: ${summary.totalExpenses}, Categories: ${summary.categoryBreakdown.length}"),
    );
    return result;
  }
}

class GetSummaryParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;

  const GetSummaryParams({this.startDate, this.endDate});

  @override
  List<Object?> get props => [startDate, endDate];
}
