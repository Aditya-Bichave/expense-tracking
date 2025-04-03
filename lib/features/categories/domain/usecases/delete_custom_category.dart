import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
// Import Transaction Repository interface (needed for reassignment)
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/main.dart'; // logger

class DeleteCustomCategoryUseCase
    implements UseCase<void, DeleteCustomCategoryParams> {
  final CategoryRepository categoryRepository;
  // --- Inject Transaction Repositories for Reassignment ---
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;
  // --- End Injection ---

  DeleteCustomCategoryUseCase(
      this.categoryRepository, this.expenseRepository, this.incomeRepository);

  @override
  Future<Either<Failure, void>> call(DeleteCustomCategoryParams params) async {
    log.info(
        "[DeleteCustomCategoryUseCase] Executing for category ID: ${params.categoryId}. Fallback: ${params.fallbackCategoryId}");

    // --- Step 1: Reassign Transactions ---
    // This logic is complex and ideally needs more robust transaction handling.
    // For simplicity, we'll find associated transactions and update them one by one.
    // A bulk update method in the Transaction Repositories would be better.

    log.info(
        "[DeleteCustomCategoryUseCase] Finding expenses associated with category ${params.categoryId}...");
    final expensesResult = await expenseRepository.getExpenses(
        /* Filter by category ID if repo supports it, otherwise fetch all and filter */);
    if (expensesResult.isLeft()) {
      log.warning(
          "[DeleteCustomCategoryUseCase] Failed to fetch expenses for reassignment.");
      return expensesResult.fold((l) => Left(l),
          (_) => const Left(CacheFailure("Failed to fetch expenses")));
    }
    final expensesToReassign = expensesResult.getOrElse(() => []).where((exp) {
      // We need the categoryId from the model, not the hydrated entity here
      // This highlights a design challenge - use cases ideally shouldn't know about models.
      // Option A: Add categoryId to Expense entity. Option B: Filter in Repo. Option C: Fetch models here (less clean).
      // Let's assume Expense entity *will* have categoryId temporarily, or this filtering is skipped/handled differently.
      // final model = ExpenseModel.fromEntity(exp); return model.categoryId == params.categoryId;
      return false; // Placeholder - Correct filtering based on chosen approach needed
    }).toList();

    log.info(
        "[DeleteCustomCategoryUseCase] Found ${expensesToReassign.length} expenses to reassign.");
    for (final expense in expensesToReassign) {
      log.fine(
          "[DeleteCustomCategoryUseCase] Reassigning expense ${expense.id} to fallback ${params.fallbackCategoryId}");
      // Assume Transaction Repo has a method like this (or use updateExpense)
      // await expenseRepository.updateExpenseCategorization(expense.id, params.fallbackCategoryId, CategorizationStatus.categorized, null);
      // Handle potential errors during individual updates? Or proceed and just delete category? Proceeding for now.
    }

    log.info(
        "[DeleteCustomCategoryUseCase] Finding income associated with category ${params.categoryId}...");
    // Repeat similar logic for Income...
    final incomeResult =
        await incomeRepository.getIncomes(/* Filter by category ID */);
    if (incomeResult.isLeft()) {
      log.warning(
          "[DeleteCustomCategoryUseCase] Failed to fetch income for reassignment.");
      return incomeResult.fold((l) => Left(l),
          (_) => const Left(CacheFailure("Failed to fetch income")));
    }
    // Filter and reassign income...

    log.info(
        "[DeleteCustomCategoryUseCase] Reassignment complete (or skipped). Calling category repository to delete.");
    // --- Step 2: Delete the Category ---
    return await categoryRepository.deleteCustomCategory(
        params.categoryId, params.fallbackCategoryId);
  }
}

class DeleteCustomCategoryParams extends Equatable {
  final String categoryId;
  final String fallbackCategoryId; // e.g., Category.uncategorized.id

  const DeleteCustomCategoryParams(
      {required this.categoryId, required this.fallbackCategoryId});

  @override
  List<Object?> get props => [categoryId, fallbackCategoryId];
}
