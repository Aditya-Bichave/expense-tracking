import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/main.dart'; // logger

/// A proxy DataSource that either interacts with the real Hive source
/// or the in-memory demo data source based on the DemoModeService.
class DemoAwareIncomeDataSource implements IncomeLocalDataSource {
  final HiveIncomeLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareIncomeDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<IncomeModel> addIncome(IncomeModel income) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareIncomeDS] Adding demo income: ${income.title}");
      return demoModeService.addDemoIncome(income);
    } else {
      return hiveDataSource.addIncome(income);
    }
  }

  @override
  Future<void> deleteIncome(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareIncomeDS] Deleting demo income ID: $id");
      return demoModeService.deleteDemoIncome(id);
    } else {
      return hiveDataSource.deleteIncome(id);
    }
  }

  @override
  Future<List<IncomeModel>> getIncomes({List<String>? categoryIds}) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareIncomeDS] Getting demo incomes.");
      final allIncomes = await demoModeService.getDemoIncomes();
      if (categoryIds == null || categoryIds.isEmpty) {
        return allIncomes;
      }
      return allIncomes
          .where((income) => categoryIds.contains(income.categoryId))
          .toList();
    } else {
      return hiveDataSource.getIncomes(categoryIds: categoryIds);
    }
  }

  @override
  Future<IncomeModel?> getIncomeById(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareIncomeDS] Getting demo income by ID: $id");
      return demoModeService.getDemoIncomeById(id);
    } else {
      return hiveDataSource.getIncomeById(id);
    }
  }

  @override
  Future<IncomeModel> updateIncome(IncomeModel income) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareIncomeDS] Updating demo income: ${income.title}");
      return demoModeService.updateDemoIncome(income);
    } else {
      return hiveDataSource.updateIncome(income);
    }
  }

  @override
  Future<void> clearAll() async {
    if (demoModeService.isDemoActive) {
      log.warning(
          "[DemoAwareIncomeDS] clearAll called in Demo Mode. Ignoring.");
      return;
    } else {
      return hiveDataSource.clearAll();
    }
  }
}
