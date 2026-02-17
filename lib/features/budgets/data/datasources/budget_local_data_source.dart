// lib/features/budgets/data/datasources/budget_local_data_source.dart
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/main.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

abstract class BudgetLocalDataSource {
  Future<List<BudgetModel>> getBudgets();
  Future<BudgetModel?> getBudgetById(String id);
  Future<void> saveBudget(BudgetModel budget); // Add/Update combined
  Future<void> deleteBudget(String id);
  Future<void> clearAllBudgets();
}

class HiveBudgetLocalDataSource implements BudgetLocalDataSource {
  final Box<BudgetModel> budgetBox;

  HiveBudgetLocalDataSource(this.budgetBox);

  @override
  Future<void> clearAllBudgets() async {
    try {
      final count = await budgetBox.clear();
      log.info("[BudgetDS] Cleared budgets box ($count items).");
    } catch (e, s) {
      log.severe("[BudgetDS] Failed to clear budgets cache$e$s");
      throw CacheFailure('Failed to clear budgets cache: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    try {
      await budgetBox.delete(id);
      log.info("[BudgetDS] Deleted budget (ID: $id).");
    } catch (e, s) {
      log.severe("[BudgetDS] Failed to delete budget (ID: $id)$e$s");
      throw CacheFailure('Failed to delete budget: ${e.toString()}');
    }
  }

  @override
  Future<BudgetModel?> getBudgetById(String id) async {
    try {
      final budget = budgetBox.get(id);
      log.fine(
        budget != null
            ? "[BudgetDS] Retrieved budget by ID $id."
            : "[BudgetDS] Budget with ID $id not found.",
      );
      return budget;
    } catch (e, s) {
      log.severe("[BudgetDS] Failed to get budget by ID $id$e$s");
      throw CacheFailure('Failed to get budget by ID: ${e.toString()}');
    }
  }

  @override
  Future<List<BudgetModel>> getBudgets() async {
    try {
      final budgets = budgetBox.values.toList();
      log.info("[BudgetDS] Retrieved ${budgets.length} budgets.");
      return budgets;
    } catch (e, s) {
      log.severe("[BudgetDS] Failed to get budgets$e$s");
      throw CacheFailure('Failed to get budgets: ${e.toString()}');
    }
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    try {
      await budgetBox.put(budget.id, budget);
      log.info(
        "[BudgetDS] Saved/Updated budget '${budget.name}' (ID: ${budget.id}).",
      );
    } catch (e, s) {
      log.severe("[BudgetDS] Failed to save budget '${budget.name}'$e$s");
      throw CacheFailure('Failed to save budget: ${e.toString()}');
    }
  }
}
