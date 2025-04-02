import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

class UpdateExpenseUseCase implements UseCase<Expense, UpdateExpenseParams> {
  final ExpenseRepository repository;

  UpdateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(UpdateExpenseParams params) async {
    // Optional: Add validation here if needed before hitting repository
    if (params.expense.title.isEmpty || params.expense.amount <= 0) {
      return Left(ValidationFailure("Title and positive amount are required."));
    }
    return await repository.updateExpense(params.expense);
  }
}

// Params class defined previously in ExpenseListBloc, ensure it's accessible or defined here
class UpdateExpenseParams extends Equatable {
  final Expense expense;

  const UpdateExpenseParams(this.expense);

  @override
  List<Object?> get props => [expense];
}
