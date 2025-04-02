import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class GetExpensesUseCase implements UseCase<List<Expense>, GetExpensesParams> {
  final ExpenseRepository repository;

  GetExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Expense>>> call(GetExpensesParams params) async {
    log.info(
        "Executing GetExpensesUseCase. Filters: AccID=${params.accountId}, Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");
    final result = await repository.getExpenses(
      startDate: params.startDate,
      endDate: params.endDate,
      category: params.category,
      accountId: params.accountId, // Pass accountId filter
    );
    result.fold(
      (failure) =>
          log.warning("[GetExpensesUseCase] Failed: ${failure.message}"),
      (expenses) => log.info(
          "[GetExpensesUseCase] Succeeded with ${expenses.length} expenses."),
    );
    return result;
  }
}

class GetExpensesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? accountId; // Add accountId filter

  const GetExpensesParams(
      {this.startDate, this.endDate, this.category, this.accountId});

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}
