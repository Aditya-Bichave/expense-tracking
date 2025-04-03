// lib/features/expenses/data/repositories/expense_repository_impl.dart
// REFINED FILE

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

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  // Use getter for lazy initialization via Service Locator
  CategoryRepository get categoryRepository => sl<CategoryRepository>();

  ExpenseRepositoryImpl({required this.localDataSource});

  // Helper function to hydrate categories for a list of expense models
  Future<Either<Failure, List<Expense>>> _hydrateCategories(
      List<ExpenseModel> expenseModels) async {
    if (expenseModels.isEmpty) return const Right([]);
    log.fine(
        "[ExpenseRepo._hydrateCategories] Hydrating ${expenseModels.length} models.");

    // Fetch all categories (leveraging repository cache if possible)
    final categoryResult = await categoryRepository.getAllCategories();
    return categoryResult.fold(
      (failure) {
        log.warning(
            "[ExpenseRepo._hydrateCategories] Failed to get categories for hydration: ${failure.message}");
        return Left(failure); // Propagate the category fetch failure
      },
      (allCategories) {
        // Create a lookup map for efficient access
        final categoryMap = {for (var cat in allCategories) cat.id: cat};
        final hydratedExpenses = <Expense>[];

        for (final model in expenseModels) {
          final category = categoryMap[model.categoryId];
          if (model.categoryId != null && category == null) {
            log.warning(
                "[ExpenseRepo._hydrateCategories] Category ID '${model.categoryId}' found on expense '${model.id}' but not in fetched category list! Treating as Uncategorized.");
          }
          // Convert model to entity and immediately add the looked-up category
          hydratedExpenses.add(Expense(
            id: model.id,
            title: model.title,
            amount: model.amount,
            date: model.date,
            accountId: model.accountId,
            status: CategorizationStatusExtension.fromValue(
                model.categorizationStatusValue),
            confidenceScore: model.confidenceScoreValue,
            // Assign looked-up category (or null if not found/not set)
            category: category,
          ));
        }
        log.fine(
            "[ExpenseRepo._hydrateCategories] Hydration complete for ${hydratedExpenses.length} expenses.");
        return Right(hydratedExpenses);
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
          "[ExpenseRepo] Add successful (ID: ${addedModel.id}). Hydrating category for return.");
      // Hydrate the single added expense
      final hydratedResult = await _hydrateCategories([addedModel]);
      return hydratedResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed hydration after adding expense '${addedModel.id}': ${failure.message}");
          // Return the failure, but the expense *was* added to the DB
          return Left(failure);
        },
        (hydratedList) => Right(hydratedList.first),
      );
    } on CacheFailure catch (e) {
      log.severe("[ExpenseRepo] CacheFailure adding expense: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error adding expense$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error adding expense: ${e.toString()}'));
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
    String? category, // Assumed to be category ID
    String? accountId,
  }) async {
    log.info(
        "[ExpenseRepo] Getting expenses. Filters: AccID=$accountId, Start=$startDate, End=$endDate, CatID=$category");
    try {
      final expenseModels = await localDataSource.getExpenses();
      log.info("[ExpenseRepo] Fetched ${expenseModels.length} expense models.");

      // Apply filtering on MODELS (before hydration)
      final originalCount = expenseModels.length;
      final filteredModels = expenseModels.where((model) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;

        // Date filtering
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
        // Account filtering
        if (accountId != null && accountId.isNotEmpty) {
          accountMatch = model.accountId == accountId;
        }
        // Category filtering (Assumes 'category' filter param holds the ID)
        if (category != null && category.isNotEmpty) {
          categoryMatch = model.categoryId == category;
        }

        return dateMatch && categoryMatch && accountMatch;
      }).toList();
      log.info(
          "[ExpenseRepo] Filtered models: ${filteredModels.length} remaining from $originalCount.");

      // Sort MODELS by date descending before hydration
      filteredModels.sort((a, b) => b.date.compareTo(a.date));
      log.fine("[ExpenseRepo] Sorted ${filteredModels.length} models.");

      // Hydrate categories for the filtered list
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
    log.info(
        "[ExpenseRepo] Updating expense '${expense.title}' (ID: ${expense.id}).");
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final updatedModel = await localDataSource.updateExpense(expenseModel);
      log.info(
          "[ExpenseRepo] Update successful (ID: ${updatedModel.id}). Hydrating category for return.");
      // Hydrate the single updated expense
      final hydratedResult = await _hydrateCategories([updatedModel]);
      return hydratedResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed hydration after updating expense '${updatedModel.id}': ${failure.message}");
          // Return the failure, but the expense *was* updated in the DB
          return Left(failure);
        },
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
    log.info(
        "[ExpenseRepo] Getting total expenses for account: $accountId, Start=$startDate, End=$endDate");
    try {
      // getExpenses filters correctly now before hydration
      final allExpensesResult = await getExpenses(
          accountId: accountId.isEmpty ? null : accountId,
          startDate: startDate,
          endDate: endDate);

      return allExpensesResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed to get expenses while calculating total for account $accountId: ${failure.message}");
          return Left(failure); // Propagate the failure
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
    log.info(
        "[ExpenseRepo] Getting expense summary. Start=$startDate, End=$endDate");
    try {
      // getExpenses now returns hydrated expenses
      final expensesResult =
          await getExpenses(startDate: startDate, endDate: endDate);

      return expensesResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed to get expenses while calculating summary: ${failure.message}");
          return Left(failure); // Propagate the failure
        },
        (expenses) {
          double total = 0;
          Map<String, double> categoryTotals = {};
          for (var expense in expenses) {
            total += expense.amount;
            // Use the hydrated category name, or 'Uncategorized' if null
            final categoryName =
                expense.category?.name ?? Category.uncategorized.name;
            categoryTotals.update(
                categoryName, (value) => value + expense.amount,
                ifAbsent: () => expense.amount);
          }
          // Sort the breakdown by amount descending
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
    log.info(
        "[ExpenseRepo] updateExpenseCategorization called for ID: $expenseId, CatID: $categoryId, Status: ${status.name}");
    try {
      // Fetch the existing model to preserve other fields
      final existingModel = await localDataSource.getExpenseById(expenseId);
      if (existingModel == null) {
        log.warning(
            "[ExpenseRepo] Expense not found for categorization update: $expenseId");
        return const Left(CacheFailure("Expense not found."));
      }

      // Create the updated model with new categorization details
      final updatedModel = ExpenseModel(
        id: existingModel.id,
        title: existingModel.title,
        amount: existingModel.amount,
        date: existingModel.date,
        accountId: existingModel.accountId,
        // --- Updated fields ---
        categoryId: categoryId, // Can be null
        categorizationStatusValue: status.value,
        confidenceScoreValue: confidenceScore,
        // --- End Updated fields ---
      );

      // Save the updated model
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
}
