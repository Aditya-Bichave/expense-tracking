import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';

// For simplicity, no NetworkInfo check for offline first
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseLocalDataSource localDataSource;
  // final NetworkInfo networkInfo; // Inject if needed for remote sync

  ExpenseRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Expense>> addExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final addedModel = await localDataSource.addExpense(expenseModel);
      return Right(addedModel.toEntity());
    } on CacheFailure catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      // Catch unexpected errors
      return Left(
          CacheFailure('Unexpected error adding expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteExpense(String id) async {
    try {
      await localDataSource.deleteExpense(id);
      return const Right(null); // Indicate success with void
    } on CacheFailure catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
          CacheFailure('Unexpected error deleting expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Expense>>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? accountId,
  }) async {
    try {
      final expenseModels = await localDataSource.getExpenses();
      List<Expense> expenses =
          expenseModels.map((model) => model.toEntity()).toList();

      // Apply filtering
      expenses = expenses.where((exp) {
        bool dateMatch = true;
        bool categoryMatch = true;
        bool accountMatch = true;

        if (startDate != null) {
          // Ensure date comparison ignores time part if only date is relevant
          final expDateOnly =
              DateTime(exp.date.year, exp.date.month, exp.date.day);
          final startDateOnly =
              DateTime(startDate.year, startDate.month, startDate.day);
          dateMatch = expDateOnly.isAfter(startDateOnly) ||
              expDateOnly.isAtSameMomentAs(startDateOnly);
        }
        if (endDate != null && dateMatch) {
          final expDateOnly =
              DateTime(exp.date.year, exp.date.month, exp.date.day);
          final endDateOnly =
              DateTime(endDate.year, endDate.month, endDate.day);
          dateMatch = expDateOnly.isBefore(endDateOnly) ||
              expDateOnly.isAtSameMomentAs(endDateOnly);
        }
        if (category != null && category.isNotEmpty) {
          categoryMatch = exp.category.name == category;
          // Could extend to subcategory if needed: exp.category.displayName == category
        }
        if (accountId != null && accountId.isNotEmpty) {
          accountMatch = exp.accountId == accountId;
        }
        return dateMatch && categoryMatch && accountMatch;
      }).toList();

      // Sort by date descending (most recent first)
      expenses.sort((a, b) => b.date.compareTo(a.date));

      return Right(expenses);
    } on CacheFailure catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
          CacheFailure('Unexpected error getting expenses: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Expense>> updateExpense(Expense expense) async {
    try {
      final expenseModel = ExpenseModel.fromEntity(expense);
      final updatedModel = await localDataSource.updateExpense(expenseModel);
      return Right(updatedModel.toEntity());
    } on CacheFailure catch (e) {
      return Left(CacheFailure(e.message));
    } catch (e) {
      return Left(
          CacheFailure('Unexpected error updating expense: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, double>> getTotalExpensesForAccount(String accountId,
      {DateTime? startDate, DateTime? endDate}) async {
    try {
      // Use the modified getExpenses to filter by account and date range
      final allExpensesResult = await getExpenses(
          accountId:
              accountId.isEmpty ? null : accountId, // Handle empty string
          startDate: startDate,
          endDate: endDate);
      return allExpensesResult.fold(
        (failure) => Left(failure),
        (expenses) {
          double total = expenses.fold(0.0, (sum, item) => sum + item.amount);
          return Right(total);
        },
      );
    } catch (e) {
      return Left(CacheFailure(
          'Failed to calculate total expenses for account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, ExpenseSummary>> getExpenseSummary({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get potentially filtered expenses first
      final expensesResult =
          await getExpenses(startDate: startDate, endDate: endDate);

      return expensesResult.fold(
        (failure) => Left(failure), // Propagate failure
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
    } catch (e) {
      return Left(CacheFailure(
          'Unexpected error calculating summary: ${e.toString()}'));
    }
  }
}
