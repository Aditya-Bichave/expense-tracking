import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';

import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:hive_ce/hive.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class DataManagementRepositoryImpl implements DataManagementRepository {
  final Box<AssetAccountModel> _accountBox;
  final Box<ExpenseModel> _expenseBox;
  final Box<IncomeModel> _incomeBox;
  final Box<CategoryModel> _categoryBox;
  final Box<UserHistoryRuleModel> _userHistoryBox;
  final Box<BudgetModel> _budgetBox;
  final Box<GoalModel> _goalBox;
  final Box<GoalContributionModel> _contributionBox;
  final Box<RecurringRuleModel> _recurringRuleBox;
  final Box<RecurringRuleAuditLogModel> _recurringRuleAuditLogBox;
  final Box<SyncMutationModel> _outboxBox;
  final Box<GroupModel> _groupBox;
  final Box<GroupMemberModel> _groupMemberBox;
  final Box<GroupExpenseModel> _groupExpenseBox;

  DataManagementRepositoryImpl({
    required Box<AssetAccountModel> accountBox,
    required Box<ExpenseModel> expenseBox,
    required Box<IncomeModel> incomeBox,
    required Box<CategoryModel> categoryBox,
    required Box<UserHistoryRuleModel> userHistoryBox,
    required Box<BudgetModel> budgetBox,
    required Box<GoalModel> goalBox,
    required Box<GoalContributionModel> contributionBox,
    required Box<RecurringRuleModel> recurringRuleBox,
    required Box<RecurringRuleAuditLogModel> recurringRuleAuditLogBox,
    required Box<SyncMutationModel> outboxBox,
    required Box<GroupModel> groupBox,
    required Box<GroupMemberModel> groupMemberBox,
    required Box<GroupExpenseModel> groupExpenseBox,
  })  : _accountBox = accountBox,
        _expenseBox = expenseBox,
        _incomeBox = incomeBox,
        _categoryBox = categoryBox,
        _userHistoryBox = userHistoryBox,
        _budgetBox = budgetBox,
        _goalBox = goalBox,
        _contributionBox = contributionBox,
        _recurringRuleBox = recurringRuleBox,
        _recurringRuleAuditLogBox = recurringRuleAuditLogBox,
        _outboxBox = outboxBox,
        _groupBox = groupBox,
        _groupMemberBox = groupMemberBox,
        _groupExpenseBox = groupExpenseBox;

  @override
  Future<Either<Failure, AllData>> getAllDataForBackup() async {
    log.info("[DataMgmtRepo] getAllDataForBackup called.");
    try {
      final accounts = _accountBox.values.toList();
      final expenses = _expenseBox.values.toList();
      final incomes = _incomeBox.values.toList();
      final categories = _categoryBox.values.toList();
      log.info(
        "[DataMgmtRepo] Fetched: ${accounts.length} accounts, ${expenses.length} expenses, ${incomes.length} incomes, ${categories.length} categories.",
      );
      return Right(
        AllData(
          accounts: accounts,
          expenses: expenses,
          incomes: incomes,
          categories: categories,
        ),
      );
    } catch (e, s) {
      log.severe("[DataMgmtRepo] Error in getAllDataForBackup$e$s");
      return Left(
        CacheFailure("Failed to retrieve data for backup: ${e.toString()}"),
      );
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
        _categoryBox.clear(),
        _userHistoryBox.clear(),
        _budgetBox.clear(),
        _goalBox.clear(),
        _contributionBox.clear(),
        _recurringRuleBox.clear(),
        _recurringRuleAuditLogBox.clear(),
        _outboxBox.clear(),
        _groupBox.clear(),
        _groupMemberBox.clear(),
        _groupExpenseBox.clear(),
      ]);
      log.info(
        "[DataMgmtRepo] All boxes cleared successfully. Cleared ${results.length} boxes.",
      );
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
          "[DataMgmtRepo] Failed to clear data before restore. Aborting.",
        );
        // Propagate the clearing failure
        return clearResult.fold(
          (failure) => Left(failure),
          (_) => const Left(CacheFailure("Unknown error during clear.")),
        );
      }
      log.info("[DataMgmtRepo] Data cleared. Proceeding with restore...");

      // 2. Restore data using putAll for efficiency
      log.info("[DataMgmtRepo] Preparing data maps for restore...");
      final Map<String, AssetAccountModel> accountMap = {
        for (var v in data.accounts) v.id: v,
      };
      final Map<String, ExpenseModel> expenseMap = {
        for (var v in data.expenses) v.id: v,
      };
      final Map<String, IncomeModel> incomeMap = {
        for (var v in data.incomes) v.id: v,
      };
      final Map<String, CategoryModel> categoryMap = {
        for (var v in data.categories) v.id: v,
      };

      log.info(
        "[DataMgmtRepo] Restoring ${accountMap.length} accounts, ${expenseMap.length} expenses, ${incomeMap.length} incomes, ${categoryMap.length} categories...",
      );

      await Future.wait([
        _accountBox.putAll(accountMap),
        _expenseBox.putAll(expenseMap),
        _incomeBox.putAll(incomeMap),
        _categoryBox.putAll(categoryMap),
      ]);

      log.info("[DataMgmtRepo] Restore completed successfully.");
      return const Right(null);
    } catch (e, s) {
      log.severe("[DataMgmtRepo] Error during restoreData population$e$s");
      return Left(RestoreFailure("Failed to restore data: ${e.toString()}"));
    }
  }
}
