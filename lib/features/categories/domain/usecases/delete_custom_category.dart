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
    this.categoryRepository,
    this.expenseRepository,
    this.incomeRepository,
  );

  @override
  Future<Either<Failure, void>> call(DeleteCustomCategoryParams params) async {
    log.info(
      "[DeleteCustomCategoryUseCase] Executing for category ID: ${params.categoryId}. Fallback Expense: ${params.fallbackExpenseCategoryId}, Fallback Income: ${params.fallbackIncomeCategoryId}",
    );

    // --- Step 1: Reassign Transactions ---
    log.info(
      "[DeleteCustomCategoryUseCase] Reassigning expenses from ${params.categoryId} to ${params.fallbackExpenseCategoryId}...",
    );
    final expenseReassignResult = await expenseRepository
        .reassignExpensesCategory(
          params.categoryId,
          params.fallbackExpenseCategoryId,
        );

    return await expenseReassignResult.fold<Future<Either<Failure, void>>>(
      (failure) async {
        log.warning(
          "[DeleteCustomCategoryUseCase] Failed to reassign expenses: ${failure.message}",
        );
        return Left(failure);
      },
      (_) async {
        log.info(
          "[DeleteCustomCategoryUseCase] Reassigning income from ${params.categoryId} to ${params.fallbackIncomeCategoryId}...",
        );
        final incomeReassignResult = await incomeRepository
            .reassignIncomesCategory(
              params.categoryId,
              params.fallbackIncomeCategoryId,
            );

        return await incomeReassignResult.fold<Future<Either<Failure, void>>>(
          (failure) async {
            log.warning(
              "[DeleteCustomCategoryUseCase] Failed to reassign income: ${failure.message}. NOT rolling back expenses to prevent data corruption.",
            );
            // Do NOT rollback expenses. Moving everything from fallback back to deleted category
            // would incorrectly move transactions that were already in the fallback category.
            // We accept partial reassignment state as safer than corruption.
            return Left(failure);
          },
          (_) async {
            log.info(
              "[DeleteCustomCategoryUseCase] Reassignment complete. Deleting category ${params.categoryId}...",
            );
            // Only delete the category if both reassignments succeeded
            // Note: Repository likely only uses fallback ID for subcategories or internal ref, passing expense fallback as primary
            return await categoryRepository.deleteCustomCategory(
              params.categoryId,
              params.fallbackExpenseCategoryId,
            );
          },
        );
      },
    );
  }
}

class DeleteCustomCategoryParams extends Equatable {
  final String categoryId;
  final String fallbackExpenseCategoryId; // e.g., Category.uncategorized.id
  final String fallbackIncomeCategoryId; // e.g., a general income category

  const DeleteCustomCategoryParams({
    required this.categoryId,
    required this.fallbackExpenseCategoryId,
    String? fallbackIncomeCategoryId,
  }) : fallbackIncomeCategoryId =
           fallbackIncomeCategoryId ?? fallbackExpenseCategoryId;

  @override
  List<Object?> get props => [
    categoryId,
    fallbackExpenseCategoryId,
    fallbackIncomeCategoryId,
  ];
}
