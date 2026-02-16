import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class UpdateExpenseUseCase implements UseCase<Expense, UpdateExpenseParams> {
  final ExpenseRepository repository;

  UpdateExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(UpdateExpenseParams params) async {
    log.info(
      "Executing UpdateExpenseUseCase for '${params.expense.title}' (ID: ${params.expense.id}).",
    );
    // Validation
    if (params.expense.title.trim().isEmpty) {
      log.warning("Validation failed: Expense title cannot be empty.");
      return const Left(ValidationFailure("Title cannot be empty."));
    }
    if (params.expense.amount <= 0) {
      log.warning("Validation failed: Expense amount must be positive.");
      return const Left(ValidationFailure("Amount must be positive."));
    }
    if (params.expense.accountId.trim().isEmpty) {
      log.warning("Validation failed: Account selection is required.");
      return const Left(ValidationFailure("Please select an account."));
    }
    return await repository.updateExpense(params.expense);
  }
}

class UpdateExpenseParams extends Equatable {
  final Expense expense;

  const UpdateExpenseParams(this.expense);

  @override
  List<Object?> get props => [expense];
}
