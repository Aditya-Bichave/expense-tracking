import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:hive/hive.dart';
import 'package:flutter/foundation.dart'; // For debugPrint

class DataManagementRepositoryImpl implements DataManagementRepository {
  final Box<AssetAccountModel> _accountBox;
  final Box<ExpenseModel> _expenseBox;
  final Box<IncomeModel> _incomeBox;

  DataManagementRepositoryImpl({
    required Box<AssetAccountModel> accountBox,
    required Box<ExpenseModel> expenseBox,
    required Box<IncomeModel> incomeBox,
  })  : _accountBox = accountBox,
        _expenseBox = expenseBox,
        _incomeBox = incomeBox;

  @override
  Future<Either<Failure, AllData>> getAllDataForBackup() async {
    debugPrint("[DataMgmtRepo] getAllDataForBackup called.");
    try {
      final accounts = _accountBox.values.toList();
      final expenses = _expenseBox.values.toList();
      final incomes = _incomeBox.values.toList();
      debugPrint(
          "[DataMgmtRepo] Fetched: ${accounts.length} accounts, ${expenses.length} expenses, ${incomes.length} incomes.");
      return Right(
          AllData(accounts: accounts, expenses: expenses, incomes: incomes));
    } catch (e, s) {
      debugPrint("[DataMgmtRepo] Error in getAllDataForBackup: $e\n$s");
      return Left(
          CacheFailure("Failed to retrieve data for backup: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllData() async {
    debugPrint("[DataMgmtRepo] clearAllData called.");
    try {
      // Clear boxes sequentially or concurrently
      await Future.wait([
        _accountBox.clear(),
        _expenseBox.clear(),
        _incomeBox.clear(),
      ]);
      debugPrint("[DataMgmtRepo] All boxes cleared successfully.");
      return const Right(null);
    } catch (e, s) {
      debugPrint("[DataMgmtRepo] Error in clearAllData: $e\n$s");
      return Left(CacheFailure("Failed to clear data: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> restoreData(AllData data) async {
    debugPrint("[DataMgmtRepo] restoreData called.");
    try {
      // 1. Clear existing data first
      final clearResult = await clearAllData();
      if (clearResult.isLeft()) {
        debugPrint(
            "[DataMgmtRepo] Failed to clear data before restore. Aborting.");
        // Propagate the clearing failure
        return clearResult.fold((failure) => Left(failure),
            (_) => const Left(CacheFailure("Unknown error during clear.")));
      }

      debugPrint("[DataMgmtRepo] Data cleared. Proceeding with restore...");

      // 2. Restore data using putAll for efficiency
      final Map<String, AssetAccountModel> accountMap = {
        for (var v in data.accounts) v.id: v
      };
      final Map<String, ExpenseModel> expenseMap = {
        for (var v in data.expenses) v.id: v
      };
      final Map<String, IncomeModel> incomeMap = {
        for (var v in data.incomes) v.id: v
      };

      await Future.wait([
        _accountBox.putAll(accountMap),
        _expenseBox.putAll(expenseMap),
        _incomeBox.putAll(incomeMap),
      ]);

      debugPrint("[DataMgmtRepo] Restore completed successfully.");
      return const Right(null);
    } catch (e, s) {
      debugPrint("[DataMgmtRepo] Error during restoreData population: $e\n$s");
      return Left(CacheFailure("Failed to restore data: ${e.toString()}"));
    }
  }
}
