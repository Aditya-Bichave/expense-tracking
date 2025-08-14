// lib/features/expenses/data/repositories/expense_repository_impl.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:collection/collection.dart'; // For firstWhereOrNull

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  final CategoryRepository categoryRepository;

  ExpenseRepositoryImpl({
    required this.localDataSource,
    required this.categoryRepository,
  });

  // Helper specifically for hydrating a single model after add/update
  Future<Either<Failure, Expense>> _hydrateSingleModel(
    ExpenseModel model,
  ) async {
    final catResult = await categoryRepository.getCategoryById(
      model.categoryId ?? '',
    );
    return catResult.fold(
      (failure) {
        log.warning(
          "[ExpenseRepo._hydrateSingleModel] Failed category lookup for ${model.id}: ${failure.message}",
        );
        return Right(model.toEntity().copyWith(categoryOrNull: () => null));
      },
      (category) {
        if (model.categoryId != null && category == null) {
          log.warning(
            "[ExpenseRepo._hydrateSingleModel] Category ID '${model.categoryId}' not found for expense ${model.id}.",
          );
        }
        return Right(model.toEntity().copyWith(categoryOrNull: () => category));
      },
    );
  }

  @override
  Future<Either<Failure, Expense>> addExpense(Expense expense) async {
    log.info("[ExpenseRepo] Adding expense '${expense.title}'.");
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final addedModel = await localDataSource.addExpense(expenseModel);
      log.info(
        "[ExpenseRepo] Add successful (ID: ${addedModel.id}). Hydrating category for return.",
      );
      return await _hydrateSingleModel(addedModel);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error adding expense$e$s");
      return Left(
        UnexpectedFailure('Unexpected error adding expense: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    log.info(
      "[ExpenseRepo] Updating expense '${expense.title}' (ID: ${expense.id}).",
    );
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final updatedModel = await localDataSource.updateExpense(expenseModel);
      log.info(
        "[ExpenseRepo] Update successful (ID: ${updatedModel.id}). Hydrating category.",
      );
      return await _hydrateSingleModel(updatedModel);
    } on CacheFailure catch (e) {
      log.warning("[ExpenseRepo] CacheFailure updating expense: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error updating expense$e$s");
      return Left(
        UnexpectedFailure('Unexpected error updating expense: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, List<ExpenseModel>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category, // Category ID
    String? accountId,
  }) async {
    log.info(
      "[ExpenseRepo] Getting expense models. Filters: AccID=$accountId, Start=$startDate, End=$endDate, CatID=$category",
    );
    try {
      final expenseModels = await localDataSource.getExpenses();
      log.fine(
        "[ExpenseRepo] Fetched ${expenseModels.length} raw expense models.",
      );

      // Apply filtering
      final filteredModels = expenseModels.where((model) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;
        if (startDate != null) {
          final expDateOnly = DateTime(
            model.date.year,
            model.date.month,
            model.date.day,
          );
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          dateMatch = !expDateOnly.isBefore(startDateOnly);
        }
        if (endDate != null && dateMatch) {
          final expDateOnly = DateTime(
            model.date.year,
            model.date.month,
            model.date.day,
          );
          // Ensure end date includes the full day
          final endDateInclusive = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          dateMatch = !model.date.isAfter(endDateInclusive);
        }
        if (accountId != null && accountId.isNotEmpty) {
          // Handle multiple account IDs if passed comma-separated
          final ids = accountId.split(',');
          accountMatch = ids.contains(model.accountId);
        }
        if (category != null && category.isNotEmpty) {
          // Handle multiple category IDs if passed comma-separated
          final ids = category.split(',');
          categoryMatch = ids.contains(model.categoryId);
        }
        return dateMatch && categoryMatch && accountMatch;
      }).toList();

      log.fine("[ExpenseRepo] Filtered to ${filteredModels.length} models.");
      filteredModels.sort((a, b) => b.date.compareTo(a.date));

      return Right(filteredModels);
    } on CacheFailure catch (e) {
      log.warning(
        "[ExpenseRepo] CacheFailure getting expense models: ${e.message}",
      );
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error getting expense models$e$s");
      return Left(
        UnexpectedFailure(
          'Unexpected error getting expense models: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    log.info("[ExpenseRepo] Deleting expense (ID: $id).");
    try {
      await localDataSource.deleteExpense(id);
      log.info("[ExpenseRepo] Delete successful for ID: $id.");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
        "[ExpenseRepo] CacheFailure deleting expense ID $id: ${e.message}",
      );
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error deleting expense ID $id$e$s");
      return Left(
        UnexpectedFailure('Unexpected error deleting expense: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpensesForAccount(
    String accountId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    log.info(
      "[ExpenseRepo] Getting total expenses for account: $accountId, Start=$startDate, End=$endDate",
    );
    try {
      final allModelsResult = await getExpenses(
        accountId: accountId.isEmpty ? null : accountId,
        startDate: startDate,
        endDate: endDate,
      );
      return allModelsResult.fold(
        (failure) {
          log.warning(
            "[ExpenseRepo] Failed to get models while calculating total for account $accountId: ${failure.message}",
          );
          return Left(failure);
        },
        (models) {
          double total = models.fold(0.0, (sum, item) => sum + item.amount);
          log.info(
            "[ExpenseRepo] Calculated total expenses for account '$accountId': $total",
          );
          return Right(total);
        },
      );
    } catch (e, s) {
      log.severe(
        "[ExpenseRepo] Unexpected error calculating total expenses for account '$accountId'$e$s",
      );
      return Left(
        UnexpectedFailure(
          'Failed to calculate total expenses: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    log.info(
      "[ExpenseRepo] Getting expense summary. Start=$startDate, End=$endDate",
    );
    try {
      final modelsResult = await getExpenses(
        startDate: startDate,
        endDate: endDate,
      );
      if (modelsResult.isLeft()) {
        return modelsResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure("Failed to get models for summary")),
        );
      }
      final expenseModels = modelsResult.getOrElse(() => []);

      final categoriesResult = await categoryRepository.getAllCategories();
      if (categoriesResult.isLeft()) {
        return categoriesResult.fold(
          (l) => Left(l),
          (_) =>
              const Left(CacheFailure("Failed to get categories for summary")),
        );
      }
      final categoryMap = {
        for (var cat in categoriesResult.getOrElse(() => [])) cat.id: cat,
      };

      double total = 0;
      Map<String, double> categoryTotals = {};
      for (var model in expenseModels) {
        total += model.amount;
        final categoryName =
            categoryMap[model.categoryId]?.name ??
            Category.uncategorized.name; // Use uncategorized name as fallback
        categoryTotals.update(
          categoryName,
          (value) => value + model.amount,
          ifAbsent: () => model.amount,
        );
      }
      final sortedCategoryTotals = Map.fromEntries(
        categoryTotals.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)),
      );
      log.info(
        "[ExpenseRepo] Calculated summary: Total=$total, Categories=${sortedCategoryTotals.length}",
      );
      return Right(
        ExpenseSummary(
          totalExpenses: total,
          categoryBreakdown: sortedCategoryTotals,
        ),
      );
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error calculating summary$e$s");
      return Left(
        UnexpectedFailure(
          'Unexpected error calculating summary: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, void>> updateExpenseCategorization(
    String expenseId,
    String? categoryId,
    CategorizationStatus status,
    double? confidenceScore,
  ) async {
    log.info(
      "[ExpenseRepo] updateExpenseCategorization called for ID: $expenseId, CatID: $categoryId, Status: ${status.name}",
    );
    try {
      final existingModel = await localDataSource.getExpenseById(expenseId);
      if (existingModel == null) {
        log.warning(
          "[ExpenseRepo] Expense not found for categorization update: $expenseId",
        );
        return const Left(CacheFailure("Expense not found."));
      }
      final updatedModel = ExpenseModel(
        id: existingModel.id,
        title: existingModel.title,
        amount: existingModel.amount,
        date: existingModel.date,
        accountId: existingModel.accountId,
        categoryId: categoryId,
        categorizationStatusValue: status.value,
        confidenceScoreValue: confidenceScore,
      );
      await localDataSource.updateExpense(updatedModel);
      log.info(
        "[ExpenseRepo] Expense categorization updated successfully for ID: $expenseId",
      );
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
        "[ExpenseRepo] CacheFailure during updateExpenseCategorization ID $expenseId: ${e.message}",
      );
      return Left(e);
    } catch (e, s) {
      log.severe(
        "[ExpenseRepo] Unexpected error in updateExpenseCategorization ID $expenseId$e$s",
      );
      return Left(
        CacheFailure(
          "Failed to update expense categorization: ${e.toString()}",
        ),
      );
    }
  }

  @override
  Future<Either<Failure, int>> reassignExpensesCategory(
    String oldCategoryId,
    String newCategoryId,
  ) async {
    log.info(
      "[ExpenseRepo] Reassigning expenses from CatID '$oldCategoryId' to '$newCategoryId'.",
    );
    int updateCount = 0;
    try {
      final allModels = await localDataSource.getExpenses();
      final modelsToUpdate = allModels
          .where((model) => model.categoryId == oldCategoryId)
          .toList();

      if (modelsToUpdate.isEmpty) {
        log.info(
          "[ExpenseRepo] No expenses found with category ID '$oldCategoryId'. No reassignment needed.",
        );
        return const Right(0);
      }
      log.info(
        "[ExpenseRepo] Found ${modelsToUpdate.length} expenses to reassign.",
      );

      List<Future<void>> updateFutures = [];
      for (final model in modelsToUpdate) {
        final updatedModel = ExpenseModel(
          id: model.id,
          title: model.title,
          amount: model.amount,
          date: model.date,
          accountId: model.accountId,
          categoryId: newCategoryId, // Assign new category ID
          categorizationStatusValue:
              CategorizationStatus.categorized.value, // Mark as categorized
          confidenceScoreValue: null, // Clear confidence
        );
        updateFutures.add(localDataSource.updateExpense(updatedModel));
        updateCount++;
      }
      await Future.wait(updateFutures);

      log.info(
        "[ExpenseRepo] Successfully triggered updates for $updateCount expenses from '$oldCategoryId' to '$newCategoryId'.",
      );
      return Right(updateCount);
    } on CacheFailure catch (e) {
      log.warning(
        "[ExpenseRepo] CacheFailure during reassignExpensesCategory: ${e.message}",
      );
      return Left(e);
    } catch (e, s) {
      log.severe(
        "[ExpenseRepo] Unexpected error during reassignExpensesCategory$e$s",
      );
      return Left(
        CacheFailure("Failed to reassign expense categories: ${e.toString()}"),
      );
    }
  }
}
