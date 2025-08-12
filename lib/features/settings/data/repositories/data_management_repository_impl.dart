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
    log.info("[DataMgmtRepo] restoreData called. Using transactional approach.");
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempAccountBoxName = 'temp_accounts_$timestamp';
    final tempExpenseBoxName = 'temp_expenses_$timestamp';
    final tempIncomeBoxName = 'temp_incomes_$timestamp';

    Box<AssetAccountModel>? tempAccountBox;
    Box<ExpenseModel>? tempExpenseBox;
    Box<IncomeModel>? tempIncomeBox;

    try {
      // 1. Open temporary boxes
      log.info("[DataMgmtRepo] Opening temporary Hive boxes.");
      tempAccountBox = await Hive.openBox<AssetAccountModel>(tempAccountBoxName);
      tempExpenseBox = await Hive.openBox<ExpenseModel>(tempExpenseBoxName);
      tempIncomeBox = await Hive.openBox<IncomeModel>(tempIncomeBoxName);

      // 2. Write data to temporary boxes to validate it
      log.info("[DataMgmtRepo] Writing data to temporary boxes for validation.");
      final Map<String, AssetAccountModel> accountMap = { for (var v in data.accounts) v.id: v };
      final Map<String, ExpenseModel> expenseMap = { for (var v in data.expenses) v.id: v };
      final Map<String, IncomeModel> incomeMap = { for (var v in data.incomes) v.id: v };

      await tempAccountBox.putAll(accountMap);
      await tempExpenseBox.putAll(expenseMap);
      await tempIncomeBox.putAll(incomeMap);
      log.info("[DataMgmtRepo] Data validation successful. Data written to temp boxes.");

      // 3. If validation succeeds, clear the main boxes
      log.info("[DataMgmtRepo] Clearing main boxes.");
      final clearResult = await clearAllData();
      if (clearResult.isLeft()) {
        log.severe("[DataMgmtRepo] Failed to clear main boxes. Aborting restore.");
        return clearResult.fold((failure) => Left(failure), (_) => const Left(CacheFailure("Unknown error during clear.")));
      }

      // 4. Copy data from temp boxes to main boxes
      log.info("[DataMgmtRepo] Copying data from temporary to main boxes.");
      await _accountBox.putAll(tempAccountBox.toMap().cast<String, AssetAccountModel>());
      await _expenseBox.putAll(tempExpenseBox.toMap().cast<String, ExpenseModel>());
      await _incomeBox.putAll(tempIncomeBox.toMap().cast<String, IncomeModel>());

      log.info("[DataMgmtRepo] Restore completed successfully.");
      return const Right(null);

    } catch (e, s) {
      log.severe("[DataMgmtRepo] Error during transactional restore: $e\n$s");
      return Left(RestoreFailure("Failed to restore data due to an error. Your original data is safe. Error: ${e.toString()}"));
    } finally {
      // 5. Clean up: close and delete temporary boxes
      log.info("[DataMgmtRepo] Cleaning up temporary boxes.");
      await tempAccountBox?.close();
      await tempExpenseBox?.close();
      await tempIncomeBox?.close();

      await Hive.deleteBoxFromDisk(tempAccountBoxName);
      await Hive.deleteBoxFromDisk(tempExpenseBoxName);
      await Hive.deleteBoxFromDisk(tempIncomeBoxName);
      log.info("[DataMgmtRepo] Cleanup complete.");
    }
  }
}
