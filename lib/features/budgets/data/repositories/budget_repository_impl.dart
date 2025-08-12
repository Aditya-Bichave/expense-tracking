// lib/features/budgets/data/repositories/budget_repository_impl.dart
// For List comparison
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart'; // Needed for calculation
import 'package:expense_tracker/main.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  final BudgetLocalDataSource localDataSource;
  final ExpenseRepository expenseRepository; // Inject expense repo

  BudgetRepositoryImpl({
    required this.localDataSource,
    required this.expenseRepository,
  });

  @override
  Future<Either<Failure, Budget>> addBudget(Budget budget) async {
    log.info("[BudgetRepo] Adding budget: ${budget.name}");
    try {
      // --- Overlap Check ---
      if (budget.type == BudgetType.categorySpecific) {
        final budgetsResult = await getBudgets(); // Fetch existing
        if (budgetsResult.isRight()) {
          final existingBudgets = budgetsResult.getOrElse(() => []);
          final overlap = _checkForOverlap(budget, existingBudgets);
          if (overlap != null) {
            log.warning(
                "[BudgetRepo] Overlap detected with budget: ${overlap.name}");
            return Left(ValidationFailure(
                "Budget overlap detected with '${overlap.name}'. Adjust categories or period."));
          }
        } else {
          log.warning(
              "[BudgetRepo] Could not perform overlap check due to error fetching existing budgets.");
          // Decide: proceed or fail? Failing is safer.
          return budgetsResult.fold(
            (failure) => Left(failure), // Propagate fetch error
            (_) =>
                const Left(CacheFailure("Failed to verify budget overlaps.")),
          );
        }
      }
      // --- End Overlap Check ---

      final model = BudgetModel.fromEntity(budget);
      await localDataSource.saveBudget(model);
      log.info("[BudgetRepo] Budget added successfully: ${budget.id}");
      return Right(budget); // Return original entity
    } catch (e, s) {
      log.severe("[BudgetRepo] Error adding budget$e$s");
      return Left(CacheFailure("Failed to add budget: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, double>> calculateAmountSpent({
    required Budget budget,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    log.fine(
        "[BudgetRepo] Calculating amount spent for budget '${budget.name}' (${budget.id}) between $periodStart and $periodEnd");
    try {
      // Fetch relevant expenses using ExpenseRepository, now with category filtering
      final expenseResult = await expenseRepository.getExpenses(
        startDate: periodStart,
        endDate: periodEnd,
        categoryIds: budget.type == BudgetType.categorySpecific ? budget.categoryIds : null,
      );

      return expenseResult.fold(
        (failure) {
          log.warning(
              "[BudgetRepo] Failed to get expenses for calculation: ${failure.message}");
          return Left(failure);
        },
        (expenseModels) {
          double totalSpent = expenseModels.fold(0.0, (sum, item) => sum + item.amount);
          log.info(
              "[BudgetRepo] Calculated total spent for '${budget.name}': $totalSpent");
          return Right(totalSpent);
        },
      );
    } catch (e, s) {
      log.severe("[BudgetRepo] Error calculating amount spent$e$s");
      return Left(
          CacheFailure("Failed to calculate budget spending: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> deleteBudget(String id) async {
    log.info("[BudgetRepo] Deleting budget: $id");
    try {
      await localDataSource.deleteBudget(id);
      log.info("[BudgetRepo] Budget deleted successfully: $id");
      return const Right(null);
    } catch (e, s) {
      log.severe("[BudgetRepo] Error deleting budget $id$e$s");
      return Left(CacheFailure("Failed to delete budget: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, Budget?>> getBudgetById(String id) async {
    log.fine("[BudgetRepo] Getting budget by ID: $id");
    try {
      final model = await localDataSource.getBudgetById(id);
      if (model != null) {
        return Right(model.toEntity());
      } else {
        return const Right(null); // Not found is not a Failure here
      }
    } catch (e, s) {
      log.severe("[BudgetRepo] Error getting budget by ID $id$e$s");
      return Left(
          CacheFailure("Failed to get budget details: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, List<Budget>>> getBudgets() async {
    log.fine("[BudgetRepo] Getting all budgets.");
    try {
      final models = await localDataSource.getBudgets();
      final entities = models.map((m) => m.toEntity()).toList();
      // Default sort: Overall first, then by name
      entities.sort((a, b) {
        if (a.type == BudgetType.overall && b.type != BudgetType.overall) {
          return -1;
        }
        if (a.type != BudgetType.overall && b.type == BudgetType.overall) {
          return 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      log.info("[BudgetRepo] Retrieved and sorted ${entities.length} budgets.");
      return Right(entities);
    } catch (e, s) {
      log.severe("[BudgetRepo] Error getting budgets$e$s");
      return Left(CacheFailure("Failed to load budgets: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, Budget>> updateBudget(Budget budget) async {
    log.info("[BudgetRepo] Updating budget: ${budget.name}");
    try {
      // --- Overlap Check (excluding self) ---
      if (budget.type == BudgetType.categorySpecific) {
        final budgetsResult = await getBudgets(); // Fetch existing
        if (budgetsResult.isRight()) {
          final existingBudgets = budgetsResult.getOrElse(() => []);
          final otherBudgets =
              existingBudgets.where((b) => b.id != budget.id).toList();
          final overlap = _checkForOverlap(budget, otherBudgets);
          if (overlap != null) {
            log.warning(
                "[BudgetRepo] Overlap detected during update with budget: ${overlap.name}");
            return Left(ValidationFailure(
                "Budget overlap detected with '${overlap.name}'. Adjust categories or period."));
          }
        } else {
          log.warning(
              "[BudgetRepo] Could not perform overlap check during update.");
          return budgetsResult.fold(
            (failure) => Left(failure), // Propagate fetch error
            (_) =>
                const Left(CacheFailure("Failed to verify budget overlaps.")),
          );
        }
      }
      // --- End Overlap Check ---

      final model = BudgetModel.fromEntity(budget);
      await localDataSource.saveBudget(model);
      log.info("[BudgetRepo] Budget updated successfully: ${budget.id}");
      return Right(budget);
    } catch (e, s) {
      log.severe("[BudgetRepo] Error updating budget$e$s");
      return Left(CacheFailure("Failed to update budget: ${e.toString()}"));
    }
  }

  // --- Helper for Overlap Check ---
  Budget? _checkForOverlap(Budget newBudget, List<Budget> existingBudgets) {
    if (newBudget.type != BudgetType.categorySpecific ||
        newBudget.categoryIds == null) {
      return null; // Only check category-specific budgets with categories
    }

    final (newStart, newEnd) = newBudget.getCurrentPeriodDates();
    final newCategorySet = newBudget.categoryIds!.toSet();

    for (final existing in existingBudgets) {
      if (existing.type != BudgetType.categorySpecific ||
          existing.categoryIds == null) {
        continue; // Skip overall or invalid budgets
      }

      // Check for category intersection
      final existingCategorySet = existing.categoryIds!.toSet();
      final intersection = newCategorySet.intersection(existingCategorySet);
      if (intersection.isEmpty) {
        continue; // No shared categories
      }

      // Check for period overlap
      final (existingStart, existingEnd) = existing.getCurrentPeriodDates();
      final periodsOverlap =
          newStart.isBefore(existingEnd) && existingStart.isBefore(newEnd);

      if (periodsOverlap) {
        log.fine(
            "Overlap found: New Budget '${newBudget.name}' ($newStart - $newEnd, Cats: ${newBudget.categoryIds}) overlaps with Existing '${existing.name}' ($existingStart - $existingEnd, Cats: ${existing.categoryIds}) on categories: $intersection");
        return existing; // Found an overlap
      }
    }
    return null; // No overlap found
  }
}
