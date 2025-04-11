import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/main.dart'; // logger

/// A proxy DataSource that either interacts with the real Hive source
/// or the in-memory demo data source based on the DemoModeService.
class DemoAwareBudgetDataSource implements BudgetLocalDataSource {
  final HiveBudgetLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareBudgetDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<List<BudgetModel>> getBudgets() async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareBudgetDS] Getting demo budgets.");
      return demoModeService.getDemoBudgets();
    } else {
      return hiveDataSource.getBudgets();
    }
  }

  @override
  Future<BudgetModel?> getBudgetById(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareBudgetDS] Getting demo budget by ID: $id");
      return demoModeService.getDemoBudgetById(id);
    } else {
      return hiveDataSource.getBudgetById(id);
    }
  }

  @override
  Future<void> saveBudget(BudgetModel budget) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareBudgetDS] Saving demo budget: ${budget.name}");
      return demoModeService.saveDemoBudget(budget);
    } else {
      return hiveDataSource.saveBudget(budget);
    }
  }

  @override
  Future<void> deleteBudget(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareBudgetDS] Deleting demo budget ID: $id");
      return demoModeService.deleteDemoBudget(id);
    } else {
      return hiveDataSource.deleteBudget(id);
    }
  }

  @override
  Future<void> clearAllBudgets() async {
    if (demoModeService.isDemoActive) {
      log.warning(
          "[DemoAwareBudgetDS] clearAllBudgets called in Demo Mode. Ignoring.");
      return;
    } else {
      return hiveDataSource.clearAllBudgets();
    }
  }
}
