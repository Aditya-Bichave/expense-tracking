// lib/features/categories/domain/usecases/delete_custom_category.dart
// MODIFIED FILE (Refined logging/error handling)
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/main.dart'; // logger

class DeleteCustomCategoryUseCase
    implements UseCase<void, DeleteCustomCategoryParams> {
  final CategoryRepository categoryRepository;
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  DeleteCustomCategoryUseCase(
      this.categoryRepository, this.expenseRepository, this.incomeRepository);

  @override
  Future<Either<Failure, void>> call(DeleteCustomCategoryParams params) async {
    log.info(
        "[DeleteCustomCategoryUseCase] Executing for category ID: ${params.categoryId}. Fallback: ${params.fallbackCategoryId}");

    // --- Step 1: Reassign Transactions ---
    log.info(
        "[DeleteCustomCategoryUseCase] Reassigning expenses from ${params.categoryId} to ${params.fallbackCategoryId}...");
    final expenseReassignResult = await expenseRepository
        .reassignExpensesCategory(params.categoryId, params.fallbackCategoryId);

    // Handle failure during expense reassignment
    Failure? reassignmentFailure;
    int expensesReassigned = 0;
    expenseReassignResult.fold((failure) {
      log.warning(
          "[DeleteCustomCategoryUseCase] Failed to reassign expenses: ${failure.message}");
      reassignmentFailure = failure;
    }, (count) => expensesReassigned = count);
    // If expense reassignment failed, stop here
    if (reassignmentFailure != null) {
      return Left(reassignmentFailure!);
    }
    log.info(
        "[DeleteCustomCategoryUseCase] Reassigned $expensesReassigned expenses.");

    log.info(
        "[DeleteCustomCategoryUseCase] Reassigning income from ${params.categoryId} to ${params.fallbackCategoryId}...");
    final incomeReassignResult = await incomeRepository.reassignIncomesCategory(
        params.categoryId, params.fallbackCategoryId);

    // Handle failure during income reassignment
    int incomeReassigned = 0;
    incomeReassignResult.fold((failure) {
      log.warning(
          "[DeleteCustomCategoryUseCase] Failed to reassign income: ${failure.message}");
      reassignmentFailure = failure; // Update failure if income fails too
    }, (count) => incomeReassigned = count);
    // If income reassignment failed, stop here
    if (reassignmentFailure != null) {
      return Left(reassignmentFailure!);
    }
    log.info(
        "[DeleteCustomCategoryUseCase] Reassigned $incomeReassigned incomes.");

    log.info(
        "[DeleteCustomCategoryUseCase] Reassignment complete. Calling category repository to delete.");
    // --- Step 2: Delete the Category ---
    // This is only called if both reassignments succeeded (or had nothing to reassign)
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
