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
  Future<List<IncomeModel>> getIncomes({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareIncomeDS] Getting demo incomes with filters.");
      final incomes = await demoModeService.getDemoIncomes();
      return incomes.where((income) {
        if (startDate != null) {
          final incDateOnly = DateTime(
            income.date.year,
            income.date.month,
            income.date.day,
          );
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          if (incDateOnly.isBefore(startDateOnly)) return false;
        }
        if (endDate != null) {
          final endDateInclusive = DateTime(
            endDate.year,
            endDate.month,
            endDate.day,
            23,
            59,
            59,
          );
          if (income.date.isAfter(endDateInclusive)) return false;
        }
        if (accountId != null && accountId.isNotEmpty) {
          final ids = accountId.split(',');
          if (!ids.contains(income.accountId)) return false;
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          final ids = categoryId.split(',');
          if (!ids.contains(income.categoryId)) return false;
        }
        return true;
      }).toList();
    } else {
      return hiveDataSource.getIncomes(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        accountId: accountId,
      );
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
        "[DemoAwareIncomeDS] clearAll called in Demo Mode. Ignoring.",
      );
      return;
    } else {
      return hiveDataSource.clearAll();
    }
  }
}
