import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart'; // Make sure Equatable is imported
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart'; // Reuse expense repo

class GetExpenseSummaryUseCase
    implements UseCase<ExpenseSummary, GetSummaryParams> {
  final ExpenseRepository repository; // Use the existing ExpenseRepository

  GetExpenseSummaryUseCase(this.repository);

  @override
  Future<Either<Failure, ExpenseSummary>> call(GetSummaryParams params) async {
    // The summary logic is now inside ExpenseRepositoryImpl
    return await repository.getExpenseSummary(
      startDate: params.startDate,
      endDate: params.endDate,
    );
  }
}

// CORRECTED: Use 'extends' for the Equatable class
class GetSummaryParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;

  const GetSummaryParams({this.startDate, this.endDate});

  @override
  List<Object?> get props =>
      [startDate, endDate]; // Define properties for equality check
}
