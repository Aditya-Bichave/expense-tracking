// lib/features/settings/domain/repositories/data_management_repository.dart

import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/core/constants/app_constants.dart'; // Import constants

// Structure for holding all data for backup/restore
class AllData {
  final List<AssetAccountModel> accounts;
  final List<ExpenseModel> expenses;
  final List<IncomeModel> incomes;
  final List<CategoryModel> categories;
  // Can add settings here in the future if needed

  AllData({
    required this.accounts,
    required this.expenses,
    required this.incomes,
    required this.categories,
  });

  // Convert to JSON structure expected by backup
  Map<String, dynamic> toJson() => {
        // Use constants for keys
        AppConstants.backupAccountsKey:
            accounts.map((a) => a.toJson()).toList(),
        AppConstants.backupExpensesKey:
            expenses.map((e) => e.toJson()).toList(),
        AppConstants.backupIncomesKey: incomes.map((i) => i.toJson()).toList(),
        'categories': categories.map((c) => c.toJson()).toList(),
      };

  // Create from JSON structure during restore
  factory AllData.fromJson(Map<String, dynamic> json) {
    // Use constants for keys and add null checks/type checks
    final accountsList =
        json[AppConstants.backupAccountsKey] as List<dynamic>? ?? [];
    final expensesList =
        json[AppConstants.backupExpensesKey] as List<dynamic>? ?? [];
    final incomesList =
        json[AppConstants.backupIncomesKey] as List<dynamic>? ?? [];
    final categoriesList = json['categories'] as List<dynamic>? ?? [];

    return AllData(
      accounts: accountsList
          .map((a) => AssetAccountModel.fromJson(a as Map<String, dynamic>))
          .toList(),
      expenses: expensesList
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      incomes: incomesList
          .map((i) => IncomeModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      categories: categoriesList
          .map((c) => CategoryModel.fromJson(c as Map<String, dynamic>))
          .toList(),
    );
  }
}

abstract class DataManagementRepository {
  Future<Either<Failure, AllData>> getAllDataForBackup();
  Future<Either<Failure, void>> clearAllData();
  Future<Either<Failure, void>> restoreData(AllData data);
}
