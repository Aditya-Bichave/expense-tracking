import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

// Returns void on success, so the Type is void
class DeleteExpenseUseCase implements UseCase<void, DeleteExpenseParams> {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteExpenseParams params) async {
    return await repository.deleteExpense(params.id);
  }
}

// Params class defined previously in ExpenseListBloc, ensure it's accessible or defined here
class DeleteExpenseParams extends Equatable {
  final String id;

  const DeleteExpenseParams(this.id);

  @override
  List<Object?> get props => [id];
}
