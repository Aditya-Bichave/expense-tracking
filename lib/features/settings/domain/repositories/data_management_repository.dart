// lib/features/settings/domain/repositories/data_management_repository.dart

import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/core/constants/app_constants.dart'; // Import constants

// Structure for holding all data for backup/restore
class AllData {
  final List<AssetAccountModel> accounts;
  final List<ExpenseModel> expenses;
  final List<IncomeModel> incomes;
  // Can add settings here in the future if needed

  AllData({
    required this.accounts,
    required this.expenses,
    required this.incomes,
  });

  // Convert to JSON structure expected by backup
  Map<String, dynamic> toJson() => {
        // Use constants for keys
        AppConstants.backupAccountsKey:
            accounts.map((a) => a.toJson()).toList(),
        AppConstants.backupExpensesKey:
            expenses.map((e) => e.toJson()).toList(),
        AppConstants.backupIncomesKey: incomes.map((i) => i.toJson()).toList(),
      };

  // Create from JSON structure during restore
  static Either<Failure, AllData> fromJson(Map<String, dynamic> json) {
    try {
      final accountsList =
          json[AppConstants.backupAccountsKey] as List<dynamic>? ?? [];
      final expensesList =
          json[AppConstants.backupExpensesKey] as List<dynamic>? ?? [];
      final incomesList =
          json[AppConstants.backupIncomesKey] as List<dynamic>? ?? [];

      final accounts = accountsList
          .map((a) => AssetAccountModel.fromJson(a as Map<String, dynamic>))
          .toList();
      final expenses = expensesList
          .map((e) => ExpenseModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final incomes = incomesList
          .map((i) => IncomeModel.fromJson(i as Map<String, dynamic>))
          .toList();

      return Right(AllData(
        accounts: accounts,
        expenses: expenses,
        incomes: incomes,
      ));
    } on TypeError catch (e) {
      return Left(ValidationFailure(
          'Invalid backup file format. A field has the wrong type. Details: $e'));
    } catch (e) {
      return Left(ValidationFailure(
          'Could not parse backup file. The file may be corrupt. Details: $e'));
    }
  }
}

abstract class DataManagementRepository {
  Future<Either<Failure, AllData>> getAllDataForBackup();
  Future<Either<Failure, void>> clearAllData();
  Future<Either<Failure, void>> restoreData(AllData data);
}
