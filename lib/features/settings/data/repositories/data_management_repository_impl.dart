import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/main.dart'; // Import logger

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
    log.info("[DataMgmtRepo] getAllDataForBackup called.");
    try {
      final accounts = _accountBox.values.toList();
      final expenses = _expenseBox.values.toList();
      final incomes = _incomeBox.values.toList();
      log.info(
          "[DataMgmtRepo] Fetched: ${accounts.length} accounts, ${expenses.length} expenses, ${incomes.length} incomes.");
      return Right(
          AllData(accounts: accounts, expenses: expenses, incomes: incomes));
    } catch (e, s) {
      log.severe("[DataMgmtRepo] Error in getAllDataForBackup$e$s");
      return Left(
          CacheFailure("Failed to retrieve data for backup: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> clearAllData() async {
    log.info("[DataMgmtRepo] clearAllData called.");
    try {
      log.info("[DataMgmtRepo] Clearing all Hive boxes...");
      // Clear boxes sequentially or concurrently
      final results = await Future.wait([
        _accountBox.clear(),
        _expenseBox.clear(),
        _incomeBox.clear(),
      ]);
      log.info(
          "[DataMgmtRepo] All boxes cleared successfully. Counts: $results");
      return const Right(null);
    } catch (e, s) {
      log.severe("[DataMgmtRepo] Error in clearAllData$e$s");
      return Left(ClearDataFailure("Failed to clear data: ${e.toString()}"));
    }
  }

  @override
  Future<Either<Failure, void>> restoreData(AllData data) async {
    log.info("[DataMgmtRepo] restoreData called.");
    try {
      // 1. Clear existing data first
      log.info("[DataMgmtRepo] Clearing existing data before restore...");
      final clearResult = await clearAllData();
      if (clearResult.isLeft()) {
        log.severe(
            "[DataMgmtRepo] Failed to clear data before restore. Aborting.");
        // Propagate the clearing failure
        return clearResult.fold((failure) => Left(failure),
            (_) => const Left(CacheFailure("Unknown error during clear.")));
      }
      log.info("[DataMgmtRepo] Data cleared. Proceeding with restore...");

      // 2. Restore data using putAll for efficiency
      log.info("[DataMgmtRepo] Preparing data maps for restore...");
      final Map<String, AssetAccountModel> accountMap = {
        for (var v in data.accounts) v.id: v
      };
      final Map<String, ExpenseModel> expenseMap = {
        for (var v in data.expenses) v.id: v
      };
      final Map<String, IncomeModel> incomeMap = {
        for (var v in data.incomes) v.id: v
      };
      log.info(
          "[DataMgmtRepo] Restoring ${accountMap.length} accounts, ${expenseMap.length} expenses, ${incomeMap.length} incomes...");

      await Future.wait([
        _accountBox.putAll(accountMap),
        _expenseBox.putAll(expenseMap),
        _incomeBox.putAll(incomeMap),
      ]);

      log.info("[DataMgmtRepo] Restore completed successfully.");
      return const Right(null);
    } catch (e, s) {
      log.severe("[DataMgmtRepo] Error during restoreData population$e$s");
      return Left(RestoreFailure("Failed to restore data: ${e.toString()}"));
    }
  }
}
