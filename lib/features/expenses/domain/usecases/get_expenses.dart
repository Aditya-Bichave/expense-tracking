import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

class GetExpensesUseCase implements UseCase<List<Expense>, GetExpensesParams> {
  final ExpenseRepository repository;

  GetExpensesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Expense>>> call(GetExpensesParams params) async {
    return await repository.getExpenses(
      startDate: params.startDate,
      endDate: params.endDate,
      category: params.category,
    );
  }
}

// Params class defined previously in ExpenseListBloc, ensure it's accessible or defined here
// If not accessible, redefine it here or move it to a shared location.
// For clarity, let's assume it's defined here or imported.
class GetExpensesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;

  const GetExpensesParams({this.startDate, this.endDate, this.category});

  @override
  List<Object?> get props => [startDate, endDate, category];
}
