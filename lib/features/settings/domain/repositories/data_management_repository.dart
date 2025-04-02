import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';

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
        'accounts': accounts.map((a) => a.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'incomes': incomes.map((i) => i.toJson()).toList(),
      };

  // Create from JSON structure during restore
  factory AllData.fromJson(Map<String, dynamic> json) {
    // Add null checks and type checks for robustness
    final accountsList = json['accounts'] as List<dynamic>? ?? [];
    final expensesList = json['expenses'] as List<dynamic>? ?? [];
    final incomesList = json['incomes'] as List<dynamic>? ?? [];

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
    );
  }
}

abstract class DataManagementRepository {
  /// Fetches all data models from their respective sources.
  Future<Either<Failure, AllData>> getAllDataForBackup();

  /// Clears all data from all sources. Use with extreme caution.
  Future<Either<Failure, void>> clearAllData();

  /// Clears existing data and restores data from the provided [AllData] object.
  Future<Either<Failure, void>> restoreData(AllData data);
}
