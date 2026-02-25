import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class DeleteExpenseUseCase implements UseCase<void, DeleteExpenseParams> {
  final ExpenseRepository repository;

  DeleteExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteExpenseParams params) async {
    log.info("Executing DeleteExpenseUseCase for ID: ${params.id}.");
    return await repository.deleteExpense(params.id);
  }
}

class DeleteExpenseParams extends Equatable {
  final String id;

  const DeleteExpenseParams(this.id);

  @override
  List<Object?> get props => [id];
}
