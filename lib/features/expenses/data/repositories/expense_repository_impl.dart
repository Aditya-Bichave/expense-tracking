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
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  final CategoryRepository categoryRepository;
  final OutboxRepository outboxRepository;
  final SyncService syncService;
  final Connectivity connectivity;

  ExpenseRepositoryImpl({
    required this.localDataSource,
    required this.categoryRepository,
    required this.outboxRepository,
    required this.syncService,
    required this.connectivity,
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

      // --- Sync Logic ---
      try {
        final outboxItem = OutboxItem(
          id: const Uuid().v4(),
          entityId: addedModel.id,
          entityType: EntityType.expense,
          opType: OpType.create,
          payloadJson: jsonEncode(addedModel.toJson()),
          createdAt: DateTime.now(),
        );
        await outboxRepository.add(outboxItem);

        final connectivityResult = await connectivity.checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi)) {
          syncService.processOutbox();
        }
      } catch (syncError) {
        log.warning(
          "[ExpenseRepo] Failed to queue expense for sync: $syncError",
        );
        // Continue, as local save was successful
      }
      // ------------------

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

      // --- Sync Logic ---
      try {
        final outboxItem = OutboxItem(
          id: const Uuid().v4(),
          entityId: updatedModel.id,
          entityType: EntityType.expense,
          opType: OpType.update,
          payloadJson: jsonEncode(updatedModel.toJson()),
          createdAt: DateTime.now(),
        );
        await outboxRepository.add(outboxItem);

        final connectivityResult = await connectivity.checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi)) {
          syncService.processOutbox();
        }
      } catch (syncError) {
        log.warning(
          "[ExpenseRepo] Failed to queue update for sync: $syncError",
        );
      }
      // ------------------

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
    String? categoryId,
    String? accountId,
  }) async {
    log.info(
      "[ExpenseRepo] Getting expense models. Filters: AccID=$accountId, Start=$startDate, End=$endDate, CatID=$categoryId",
    );
    try {
      final expenseModels = await localDataSource.getExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        accountId: accountId,
      );
      log.fine(
        "[ExpenseRepo] Retrieved ${expenseModels.length} expense models after filtering.",
      );
      expenseModels.sort((a, b) => b.date.compareTo(a.date));
      return Right(expenseModels);
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

      // --- Sync Logic ---
      try {
        final outboxItem = OutboxItem(
          id: const Uuid().v4(),
          entityId: id,
          entityType: EntityType.expense,
          opType: OpType.delete,
          payloadJson: jsonEncode({'id': id}),
          createdAt: DateTime.now(),
        );
        await outboxRepository.add(outboxItem);

        final connectivityResult = await connectivity.checkConnectivity();
        if (connectivityResult.contains(ConnectivityResult.mobile) ||
            connectivityResult.contains(ConnectivityResult.wifi)) {
          syncService.processOutbox();
        }
      } catch (syncError) {
        log.warning(
          "[ExpenseRepo] Failed to queue delete for sync: $syncError",
        );
      }
      // ------------------

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
