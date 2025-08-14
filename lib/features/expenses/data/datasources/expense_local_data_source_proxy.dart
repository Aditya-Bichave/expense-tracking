import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/main.dart'; // logger

/// A proxy DataSource that either interacts with the real Hive source
/// or the in-memory demo data source based on the DemoModeService.
class DemoAwareExpenseDataSource implements ExpenseLocalDataSource {
  final HiveExpenseLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareExpenseDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<ExpenseModel> addExpense(ExpenseModel expense) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareExpenseDS] Adding demo expense: ${expense.title}");
      // In demo mode, add to the in-memory list via DemoModeService
      return demoModeService.addDemoExpense(expense);
    } else {
      // In live mode, forward to the real Hive data source
      return hiveDataSource.addExpense(expense);
    }
  }

  @override
  Future<void> deleteExpense(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareExpenseDS] Deleting demo expense ID: $id");
      // In demo mode, remove from the in-memory list
      return demoModeService.deleteDemoExpense(id);
    } else {
      // In live mode, forward to Hive
      return hiveDataSource.deleteExpense(id);
    }
  }

  @override
  Future<List<ExpenseModel>> getExpenses({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? accountId,
  }) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareExpenseDS] Getting demo expenses with filters.");
      final expenses = await demoModeService.getDemoExpenses();
      return expenses.where((expense) {
        if (startDate != null) {
          final expDateOnly = DateTime(
            expense.date.year,
            expense.date.month,
            expense.date.day,
          );
          final startDateOnly = DateTime(
            startDate.year,
            startDate.month,
            startDate.day,
          );
          if (expDateOnly.isBefore(startDateOnly)) return false;
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
          if (expense.date.isAfter(endDateInclusive)) return false;
        }
        if (accountId != null && accountId.isNotEmpty) {
          final ids = accountId.split(',');
          if (!ids.contains(expense.accountId)) return false;
        }
        if (categoryId != null && categoryId.isNotEmpty) {
          final ids = categoryId.split(',');
          if (!ids.contains(expense.categoryId)) return false;
        }
        return true;
      }).toList();
    } else {
      // Return live data from Hive
      return hiveDataSource.getExpenses(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        accountId: accountId,
      );
    }
  }

  @override
  Future<ExpenseModel?> getExpenseById(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareExpenseDS] Getting demo expense by ID: $id");
      return demoModeService.getDemoExpenseById(id);
    } else {
      return hiveDataSource.getExpenseById(id);
    }
  }

  @override
  Future<ExpenseModel> updateExpense(ExpenseModel expense) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareExpenseDS] Updating demo expense: ${expense.title}");
      // Update the in-memory list
      return demoModeService.updateDemoExpense(expense);
    } else {
      // Forward to Hive
      return hiveDataSource.updateExpense(expense);
    }
  }

  @override
  Future<void> clearAll() async {
    if (demoModeService.isDemoActive) {
      log.warning(
        "[DemoAwareExpenseDS] clearAll called in Demo Mode. Ignoring.",
      );
      // Do nothing in demo mode for clearAll data sources
      return;
    } else {
      return hiveDataSource.clearAll();
    }
  }
}
