// lib/features/expenses/data/repositories/expense_repository_impl.dart
// MODIFIED FILE
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/utils/enums.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
// REMOVED: import 'package:hive/hive.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  CategoryRepository get categoryRepository => sl<CategoryRepository>();

  ExpenseRepositoryImpl({required this.localDataSource});

  // --- Helper function to hydrate categories ---
  Future<Either<Failure, List<Expense>>> _hydrateCategories(
      List<ExpenseModel> expenseModels) async {
    if (expenseModels.isEmpty) return const Right([]);
    log.fine(
        "[ExpenseRepo._hydrateCategories] Hydrating ${expenseModels.length} models.");
    final categoryResult = await categoryRepository.getAllCategories();
    return categoryResult.fold(
      (failure) {
        log.warning(
            "[ExpenseRepo._hydrateCategories] Failed to get categories for hydration: ${failure.message}");
        return Left(failure);
      },
      (allCategories) {
        final categoryMap = {for (var cat in allCategories) cat.id: cat};
        final hydratedExpenses = <Expense>[];
        for (final model in expenseModels) {
          final category = categoryMap[model.categoryId];
          if (model.categoryId != null && category == null) {
            log.warning(
                "[ExpenseRepo._hydrateCategories] Category ID '${model.categoryId}' found on expense '${model.id}' but not in fetched category list! Treating as Uncategorized.");
          }
          hydratedExpenses.add(Expense(
            id: model.id,
            title: model.title,
            amount: model.amount,
            date: model.date,
            accountId: model.accountId,
            status: CategorizationStatusExtension.fromValue(
                model.categorizationStatusValue),
            confidenceScore: model.confidenceScoreValue,
            category: category,
          ));
        }
        log.fine(
            "[ExpenseRepo._hydrateCategories] Hydration complete for ${hydratedExpenses.length} expenses.");
        return Right(hydratedExpenses);
      },
    );
  }
  // --- End Helper ---

  // addExpense, deleteExpense, getExpenses, updateExpense, getTotalExpensesForAccount, getExpenseSummary remain the same
  @override
  Future<Either<Failure, Expense>> addExpense(Expense expense) async {
    /* ... implementation ... */ log
        .info("[ExpenseRepo] Adding expense '${expense.title}'.");
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final addedModel = await localDataSource.addExpense(expenseModel);
      log.info(
          "[ExpenseRepo] Add successful (ID: ${addedModel.id}). Hydrating category for return.");
      final hydratedResult = await _hydrateCategories([addedModel]);
      return hydratedResult.fold(
        (failure) => Left(failure),
        (hydratedList) => Right(hydratedList.first),
      );
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error adding expense$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error adding expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    /* ... implementation ... */ log
        .info("[ExpenseRepo] Deleting expense (ID: $id).");
    try {
      await localDataSource.deleteExpense(id);
      log.info("[ExpenseRepo] Delete successful for ID: $id.");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
          "[ExpenseRepo] CacheFailure deleting expense ID $id: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error deleting expense ID $id$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error deleting expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountId,
  }) async {
    /* ... implementation ... */ log.info(
        "[ExpenseRepo] Getting expenses. Filters: AccID=$accountId, Start=$startDate, End=$endDate, CatID=$category");
    try {
      final expenseModels = await localDataSource.getExpenses();
      log.info("[ExpenseRepo] Fetched ${expenseModels.length} expense models.");
      final originalCount = expenseModels.length;
      final filteredModels = expenseModels.where((model) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;
        if (startDate != null) {
          final expDateOnly =
              DateTime(model.date.year, model.date.month, model.date.day);
          final startDateOnly =
              DateTime(startDate.year, startDate.month, startDate.day);
          dateMatch = !expDateOnly.isBefore(startDateOnly);
        }
        if (endDate != null && dateMatch) {
          final expDateOnly =
              DateTime(model.date.year, model.date.month, model.date.day);
          final endDateOnly =
              DateTime(endDate.year, endDate.month, endDate.day);
          dateMatch = !expDateOnly.isAfter(endDateOnly);
        }
        if (accountId != null && accountId.isNotEmpty) {
          accountMatch = model.accountId == accountId;
        }
        if (category != null && category.isNotEmpty) {
          categoryMatch = model.categoryId == category;
        }
        return dateMatch && categoryMatch && accountMatch;
      }).toList();
      log.info(
          "[ExpenseRepo] Filtered models: ${filteredModels.length} remaining from $originalCount.");
      filteredModels.sort((a, b) => b.date.compareTo(a.date));
      log.fine("[ExpenseRepo] Sorted ${filteredModels.length} models.");
      return await _hydrateCategories(filteredModels);
    } on CacheFailure catch (e) {
      log.warning("[ExpenseRepo] CacheFailure getting expenses: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error getting expenses$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error getting expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    /* ... implementation ... */ log.info(
        "[ExpenseRepo] Updating expense '${expense.title}' (ID: ${expense.id}).");
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final updatedModel = await localDataSource.updateExpense(expenseModel);
      log.info(
          "[ExpenseRepo] Update successful (ID: ${updatedModel.id}). Hydrating category for return.");
      final hydratedResult = await _hydrateCategories([updatedModel]);
      return hydratedResult.fold(
        (failure) => Left(failure),
        (hydratedList) => Right(hydratedList.first),
      );
    } on CacheFailure catch (e) {
      log.warning("[ExpenseRepo] CacheFailure updating expense: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error updating expense$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error updating expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpensesForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate}) async {
    /* ... implementation ... */ log.info(
        "[ExpenseRepo] Getting total expenses for account: $accountId, Start=$startDate, End=$endDate");
    try {
      final allExpensesResult = await getExpenses(
          accountId: accountId.isEmpty ? null : accountId,
          startDate: startDate,
          endDate: endDate);
      return allExpensesResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed to get expenses while calculating total for account $accountId: ${failure.message}");
          return Left(failure);
        },
        (expenses) {
          double total = expenses.fold(0.0, (sum, item) => sum + item.amount);
          log.info(
              "[ExpenseRepo] Calculated total expenses for account '$accountId': $total");
          return Right(total);
        },
      );
    } catch (e, s) {
      log.severe(
          "[ExpenseRepo] Unexpected error calculating total expenses for account '$accountId'$e$s");
      return Left(UnexpectedFailure(
          'Failed to calculate total expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary(
      {DateTime? startDate, DateTime? endDate}) async {
    /* ... implementation ... */ log.info(
        "[ExpenseRepo] Getting expense summary. Start=$startDate, End=$endDate");
    try {
      final expensesResult =
          await getExpenses(startDate: startDate, endDate: endDate);
      return expensesResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed to get expenses while calculating summary: ${failure.message}");
          return Left(failure);
        },
        (expenses) {
          double total = 0;
          Map<String, double> categoryTotals = {};
          for (var expense in expenses) {
            total += expense.amount;
            final categoryName =
                expense.category?.name ?? Category.uncategorized.name;
            categoryTotals.update(
                categoryName, (value) => value + expense.amount,
                ifAbsent: () => expense.amount);
          }
          final sortedCategoryTotals = Map.fromEntries(
              categoryTotals.entries.toList()
                ..sort((e1, e2) => e2.value.compareTo(e1.value)));
          log.info(
              "[ExpenseRepo] Calculated summary: Total=$total, Categories=${sortedCategoryTotals.length}");
          return Right(ExpenseSummary(
              totalExpenses: total, categoryBreakdown: sortedCategoryTotals));
        },
      );
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error calculating summary$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error calculating summary: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updateExpenseCategorization(
      String expenseId,
      String? categoryId,
      CategorizationStatus status,
      double? confidenceScore) async {
    /* ... implementation ... */ log.info(
        "[ExpenseRepo] updateExpenseCategorization called for ID: $expenseId, CatID: $categoryId, Status: ${status.name}");
    try {
      final existingModel = await localDataSource.getExpenseById(expenseId);
      if (existingModel == null) {
        log.warning(
            "[ExpenseRepo] Expense not found for categorization update: $expenseId");
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
          confidenceScoreValue: confidenceScore);
      await localDataSource.updateExpense(updatedModel);
      log.info(
          "[ExpenseRepo] Expense categorization updated successfully for ID: $expenseId");
      return const Right(null);
    } on CacheFailure catch (e) {
      log.warning(
          "[ExpenseRepo] CacheFailure during updateExpenseCategorization ID $expenseId: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe(
          "[ExpenseRepo] Unexpected error in updateExpenseCategorization ID $expenseId$e$s");
      return Left(CacheFailure(
          "Failed to update expense categorization: ${e.toString()}"));
    }
  }

  // --- MODIFIED IMPLEMENTATION ---
  @override
  Future<Either<Failure, int>> reassignExpensesCategory(
      String oldCategoryId, String newCategoryId) async {
    log.info(
        "[ExpenseRepo] Reassigning expenses from CatID '$oldCategoryId' to '$newCategoryId'.");
    int updateCount = 0;
    try {
      // 1. Fetch all models (less efficient, but avoids direct box access)
      final allModels = await localDataSource.getExpenses();
      final modelsToUpdate = allModels
          .where((model) => model.categoryId == oldCategoryId)
          .toList();

      if (modelsToUpdate.isEmpty) {
        log.info(
            "[ExpenseRepo] No expenses found with category ID '$oldCategoryId'. No reassignment needed.");
        return const Right(0);
      }

      log.info(
          "[ExpenseRepo] Found ${modelsToUpdate.length} expenses to reassign.");

      // 2. Update each model individually via the DataSource
      List<Future<void>> updateFutures = [];
      for (final model in modelsToUpdate) {
        final updatedModel = ExpenseModel(
          id: model.id,
          title: model.title,
          amount: model.amount,
          date: model.date,
          accountId: model.accountId,
          categoryId: newCategoryId, // Assign new category ID
          categorizationStatusValue: CategorizationStatus.categorized.value,
          confidenceScoreValue: null,
        );
        // Add the update future to the list
        updateFutures.add(localDataSource.updateExpense(updatedModel));
        updateCount++;
      }

      // 3. Wait for all individual updates to complete
      await Future.wait(updateFutures);

      log.info(
          "[ExpenseRepo] Successfully triggered updates for $updateCount expenses from '$oldCategoryId' to '$newCategoryId'.");
      return Right(updateCount);
    } on CacheFailure catch (e) {
      log.warning(
          "[ExpenseRepo] CacheFailure during reassignExpensesCategory: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe(
          "[ExpenseRepo] Unexpected error during reassignExpensesCategory$e$s");
      return Left(CacheFailure(
          "Failed to reassign expense categories: ${e.toString()}"));
    }
  }
  // --- END MODIFIED ---
}
