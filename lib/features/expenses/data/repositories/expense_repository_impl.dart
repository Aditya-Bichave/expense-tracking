import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Expense>> addExpense(Expense expense) async {
    log.info("[ExpenseRepo] Adding expense '${expense.title}'.");
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final addedModel = await localDataSource.addExpense(expenseModel);
      log.info("[ExpenseRepo] Add successful. Returning entity.");
      return Right(addedModel.toEntity());
    } on CacheFailure catch (e) {
      log.warning("[ExpenseRepo] CacheFailure during add: ${e.message}");
      return Left(e); // Propagate specific failure
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
      log.info("[ExpenseRepo] Delete successful.");
      return const Right(null); // Indicate success with void
    } on CacheFailure catch (e) {
      log.warning("[ExpenseRepo] CacheFailure during delete: ${e.message}");
      return Left(e);
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error deleting expense$e$s");
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
    log.info(
        "[ExpenseRepo] Getting expenses. Filters: AccID=$accountId, Start=$startDate, End=$endDate, Cat=$category");
    try {
      final expenseModels = await localDataSource.getExpenses();
      List<Expense> expenses =
          expenseModels.map((model) => model.toEntity()).toList();
      log.info("[ExpenseRepo] Fetched and mapped ${expenses.length} expenses.");

      // Apply filtering
      final originalCount = expenses.length;
      expenses = expenses.where((exp) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;

        // Date filtering (inclusive)
        if (startDate != null) {
          final expDateOnly =
              DateTime(exp.date.year, exp.date.month, exp.date.day);
          final startDateOnly =
              DateTime(startDate.year, startDate.month, startDate.day);
          dateMatch = !expDateOnly.isBefore(startDateOnly);
        }
        if (endDate != null && dateMatch) {
          final expDateOnly =
              DateTime(exp.date.year, exp.date.month, exp.date.day);
          final endDateOnly =
              DateTime(endDate.year, endDate.month, endDate.day);
          dateMatch = !expDateOnly.isAfter(endDateOnly);
        }
        // Category filtering
        if (category != null && category.isNotEmpty) {
          categoryMatch = exp.category.name == category;
        }
        // Account filtering
        if (accountId != null && accountId.isNotEmpty) {
          accountMatch = exp.accountId == accountId;
        }
        return dateMatch && categoryMatch && accountMatch;
      }).toList();
      log.info(
          "[ExpenseRepo] Filtered expenses: ${expenses.length} remaining from $originalCount.");

      // Sort by date descending (most recent first)
      expenses.sort((a, b) => b.date.compareTo(a.date));
      log.info("[ExpenseRepo] Sorted expenses.");

      return Right(expenses);
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
      log.info("[ExpenseRepo] Update successful. Returning entity.");
      return Right(updatedModel.toEntity());
    } on CacheFailure catch (e) {
      log.warning("[ExpenseRepo] CacheFailure during update: ${e.message}");
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
      final allExpensesResult = await getExpenses(
          accountId: accountId.isEmpty ? null : accountId,
          startDate: startDate,
          endDate: endDate);

      return allExpensesResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed to get expenses while calculating total: ${failure.message}");
          return Left(failure); // Propagate the failure
        },
        (expenses) {
          double total = expenses.fold(0.0, (sum, item) => sum + item.amount);
          log.info(
              "[ExpenseRepo] Calculated total expenses for account $accountId: $total");
          return Right(total);
        },
      );
    } catch (e, s) {
      log.severe(
          "[ExpenseRepo] Unexpected error calculating total expenses for account $accountId$e$s");
      return Left(UnexpectedFailure(
          'Failed to calculate total expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    log.info(
        "[ExpenseRepo] Getting expense summary. Start=$startDate, End=$endDate");
    try {
      final expensesResult =
          await getExpenses(startDate: startDate, endDate: endDate);

      return expensesResult.fold(
        (failure) {
          log.warning(
              "[ExpenseRepo] Failed to get expenses while calculating summary: ${failure.message}");
          return Left(failure); // Propagate failure
        },
        (expenses) {
          double total = 0;
          Map<String, double> categoryTotals = {};

          for (var expense in expenses) {
            total += expense.amount;
            categoryTotals.update(
              expense.category.name, // Group by main category name
              (value) => value + expense.amount,
              ifAbsent: () => expense.amount,
            );
          }
          log.info(
              "[ExpenseRepo] Calculated summary: Total=$total, Categories=${categoryTotals.length}");

          // Sort category breakdown by amount descending
          final sortedCategoryTotals = Map.fromEntries(
              categoryTotals.entries.toList()
                ..sort((e1, e2) => e2.value.compareTo(e1.value)));

          return Right(ExpenseSummary(
            totalExpenses: total,
            categoryBreakdown: sortedCategoryTotals,
          ));
        },
      );
    } catch (e, s) {
      log.severe("[ExpenseRepo] Unexpected error calculating summary$e$s");
      return Left(UnexpectedFailure(
          'Unexpected error calculating summary: ${e.toString()}'));
    }
  }
}
