import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

class GetExpensesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId; // Changed to match repository param name
  final String? accountId;

  const GetExpensesParams({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
  });

  @override
  List<Object?> get props => [startDate, endDate, categoryId, accountId];
}

class GetExpensesUseCase implements UseCase<List<ExpenseModel>, GetExpensesParams> {
  final ExpenseRepository repository;

  GetExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<ExpenseModel>>> call(GetExpensesParams params) async {
    return await repository.getExpenses(
      startDate: params.startDate,
      endDate: params.endDate,
      categoryId: params.categoryId,
      accountId: params.accountId,
    );
  }
}
