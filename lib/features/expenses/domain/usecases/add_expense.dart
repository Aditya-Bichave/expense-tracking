import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

class AddExpenseUseCase implements UseCase<Expense, AddExpenseParams> {
  final ExpenseRepository repository;

  AddExpenseUseCase(this.repository);

  @override
  Future<Either<Failure, Expense>> call(AddExpenseParams params) async {
    // Basic validation can happen here or in the BLoC
    if (params.expense.title.isEmpty || params.expense.amount <= 0) {
      return Left(ValidationFailure("Title and positive amount are required."));
    }
    return await repository.addExpense(params.expense);
  }
}

class AddExpenseParams {
  // Using a Params class is good practice
  final Expense expense;
  AddExpenseParams(this.expense);
}

// --- Implement other use cases similarly ---
// GetExpensesUseCase(repository) -> call(GetExpensesParams(startDate, endDate, category)) -> repository.getExpenses(...)
// UpdateExpenseUseCase(repository) -> call(UpdateExpenseParams(expense)) -> repository.updateExpense(...)
// DeleteExpenseUseCase(repository) -> call(DeleteExpenseParams(id)) -> repository.deleteExpense(...)