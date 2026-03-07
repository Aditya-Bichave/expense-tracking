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
import 'package:collection/collection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/expenses/domain/utils/split_engine.dart';

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  final CategoryRepository categoryRepository;
  final SupabaseClient supabaseClient;

  ExpenseRepositoryImpl({
    required this.localDataSource,
    required this.categoryRepository,
    required this.supabaseClient,
  });

  Future<Either<Failure, Expense>> _hydrateSingleModel(
    ExpenseModel model,
  ) async {
    // Helper to hydrate category
    Category? category;
    if (model.categoryId != null) {
      final categoryResult = await categoryRepository.getCategoryById(
        model.categoryId!,
      );
      category = categoryResult.fold((l) => null, (r) => r);
    }
    return Right(
      model.toEntity().copyWith(
        category: category,
        categoryOrNull: () => category, // Explicitly set category
      ),
    );
  }

  @override
  Future<Either<Failure, Expense>> addExpense(Expense expense) async {
    log.info(
      "[ExpenseRepo] Adding expense: ${expense.title} (ID: ${expense.id})",
    );
    try {
      final model = ExpenseModel.fromEntity(expense);
      await localDataSource.addExpense(model);
      log.info("[ExpenseRepo] Expense added locally.");
      return await _hydrateSingleModel(model);
    } on CacheFailure catch (e) {
      log.warning("[ExpenseRepo] CacheFailure adding expense: ${e.message}");
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
    log.info("[ExpenseRepo] Updating expense: ${expense.id}");
    try {
      final model = ExpenseModel.fromEntity(expense);
      await localDataSource.updateExpense(model);
      log.info("[ExpenseRepo] Update successful (ID: ${model.id}).");
      return await _hydrateSingleModel(model);
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
  Future<Either<Failure, Expense?>> getExpenseById(String id) async {
    try {
      final model = await localDataSource.getExpenseById(id);
      if (model == null) return const Right(null);
      final hydratedResult = await _hydrateSingleModel(model);
      return hydratedResult;
    } catch (e) {
      log.severe("Error getting expense by ID $id: $e");
      return Left(CacheFailure("Error getting expense: $e"));
    }
  }

  @override
  Future<Either<Failure, List<ExpenseModel>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    log.info("[ExpenseRepo] Getting expense models. Filters: AccID=$accountId");
    try {
      final expenseModels = await localDataSource.getExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        accountId: accountId,
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
    try {
      await localDataSource.deleteExpense(id);
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpensesForAccount(
    String accountId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final allModelsResult = await getExpenses(
        accountId: accountId.isEmpty ? null : accountId,
        startDate: startDate,
        endDate: endDate,
      );
      return allModelsResult.fold((failure) => Left(failure), (models) {
        double total = models.fold(0.0, (sum, item) => sum + item.amount);
        return Right(total);
      });
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final modelsResult = await getExpenses(
        startDate: startDate,
        endDate: endDate,
      );
      if (modelsResult.isLeft()) {
        return modelsResult.fold(
          (l) => Left(l),
          (_) => const Left(CacheFailure()),
        );
      }
      final expenseModels = modelsResult.getOrElse(() => []);

      final categoriesResult = await categoryRepository.getAllCategories();
      final categoryMap = categoriesResult.fold(
        (l) => <String, Category>{},
        (cats) => {for (var c in cats) c.id: c},
      );

      double total = 0;
      Map<String, double> categoryTotals = {};
      for (var model in expenseModels) {
        total += model.amount;
        final categoryName =
            categoryMap[model.categoryId]?.name ?? Category.uncategorized.name;
        categoryTotals.update(
          categoryName,
          (v) => v + model.amount,
          ifAbsent: () => model.amount,
        );
      }
      final sorted = Map.fromEntries(
        categoryTotals.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value)),
      );
      return Right(
        ExpenseSummary(totalExpenses: total, categoryBreakdown: sorted),
      );
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateExpenseCategorization(
    String expenseId,
    String? categoryId,
    CategorizationStatus status,
    double? confidenceScore,
  ) async {
    try {
      final existing = await localDataSource.getExpenseById(expenseId);
      if (existing == null)
        return const Left(CacheFailure("Expense not found"));

      // We can't use copyWith easily on Model as it doesn't exist, constructing new one
      final updated = ExpenseModel(
        id: existing.id,
        title: existing.title,
        amount: existing.amount,
        date: existing.date,
        accountId: existing.accountId,
        categoryId: categoryId,
        categorizationStatusValue: status.value,
        confidenceScoreValue: confidenceScore,
        isRecurring: existing.isRecurring,
        merchantId: existing.merchantId,
        groupId: existing.groupId,
        createdBy: existing.createdBy,
        currency: existing.currency,
        notes: existing.notes,
        payers: existing.payers,
        splits: existing.splits,
      );
      await localDataSource.updateExpense(updated);
      return const Right(null);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> reassignExpensesCategory(
    String oldId,
    String newId,
  ) async {
    try {
      final all = await localDataSource.getExpenses();
      final toUpdate = all.where((m) => m.categoryId == oldId).toList();
      if (toUpdate.isEmpty) return const Right(0);

      List<Future<void>> futures = [];
      for (var m in toUpdate) {
        final updated = ExpenseModel(
          id: m.id,
          title: m.title,
          amount: m.amount,
          date: m.date,
          accountId: m.accountId,
          categoryId: newId,
          categorizationStatusValue: CategorizationStatus.categorized.value,
          confidenceScoreValue: null,
          isRecurring: m.isRecurring,
          merchantId: m.merchantId,
          groupId: m.groupId,
          createdBy: m.createdBy,
          currency: m.currency,
          notes: m.notes,
          payers: m.payers,
          splits: m.splits,
        );
        futures.add(localDataSource.updateExpense(updated));
      }
      await Future.wait(futures);
      return Right(toUpdate.length);
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }

  // --- NEW METHOD ---
  @override
  Future<Either<Failure, Expense>> createExpenseTransaction(
    Expense expense,
  ) async {
    log.info("[ExpenseRepo] creating expense transaction via RPC");
    try {
      // 1. Validate with SplitEngine
      log.info("[ExpenseRepo] Validating splits locally...");
      SplitEngine.calculateSplits(
        totalAmount: expense.amount,
        splits: expense.splits,
      );
      SplitEngine.validatePayers(
        totalAmount: expense.amount,
        payers: expense.payers,
      );

      // 2. Prepare payload
      final model = ExpenseModel.fromEntity(expense);
      final payload = model.toRpcJson();

      // 3. Call RPC
      log.info("[ExpenseRepo] Calling create_expense_transaction RPC...");
      final String expenseId = await supabaseClient.rpc(
        'create_expense_transaction',
        params: payload,
      );

      log.info("[ExpenseRepo] RPC success. New ID: $expenseId");

      // 4. Return updated expense
      final updatedExpense = expense.copyWith(id: expenseId);

      // Optionally save to local?
      // await localDataSource.addExpense(ExpenseModel.fromEntity(updatedExpense));

      return Right(updatedExpense);
    } on PostgrestException catch (e) {
      log.severe("[ExpenseRepo] RPC Failed: ${e.message}");
      return Left(ServerFailure('Supabase Error: ${e.message}'));
    } on ValidationException catch (e) {
      log.warning("[ExpenseRepo] Validation Failed: ${e.message}");
      return Left(ValidationFailure(e.message));
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error in transaction: $e\n$s");
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
