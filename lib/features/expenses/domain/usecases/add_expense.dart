import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/utils/logger.dart';

class AddExpenseUseCase implements UseCase<Expense, AddExpenseParams> {
  final ExpenseRepository repository;

  AddExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(AddExpenseParams params) async {
    log.info("Executing AddExpenseUseCase for '${params.expense.title}'.");
    // Basic validation
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
    // Category validation happens implicitly via dropdown selection
    return await repository.addExpense(params.expense);
  }
}

class AddExpenseParams extends Equatable {
  final Expense expense;

  const AddExpenseParams(this.expense);

  @override
  List<Object?> get props => [expense];
}
