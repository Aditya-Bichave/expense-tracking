import 'package:expense_tracker/core/data/demo_data.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/utils/e2e_mode.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class E2EBootstrap {
  static Future<void> seedLocalState() async {
    if (!E2EMode.enabled) {
      return;
    }

    log.info('[E2EBootstrap] Resetting local test state.');

    final prefs = sl<SharedPreferences>();
    await prefs.clear();

    final secureStorageService = sl<SecureStorageService>();
    await secureStorageService.deletePin();
    await secureStorageService.setBiometricEnabled(false);

    await Future.wait([
      sl<Box<ExpenseModel>>().clear(),
      sl<Box<AssetAccountModel>>().clear(),
      sl<Box<IncomeModel>>().clear(),
      sl<Box<CategoryModel>>().clear(),
      sl<Box<UserHistoryRuleModel>>().clear(),
      sl<Box<BudgetModel>>().clear(),
      sl<Box<GoalModel>>().clear(),
      sl<Box<GoalContributionModel>>().clear(),
      sl<Box<RecurringRuleModel>>().clear(),
      sl<Box<RecurringRuleAuditLogModel>>().clear(),
      sl<Box<SyncMutationModel>>().clear(),
      sl<Box<GroupModel>>().clear(),
      sl<Box<GroupMemberModel>>().clear(),
      sl<Box<GroupExpenseModel>>().clear(),
      sl<Box<ProfileModel>>().clear(),
    ]);

    await Future.wait([
      _seedBox<ExpenseModel>(sl<Box<ExpenseModel>>(), DemoData.sampleExpenses),
      _seedBox<AssetAccountModel>(
        sl<Box<AssetAccountModel>>(),
        DemoData.sampleAccounts,
      ),
      _seedBox<IncomeModel>(sl<Box<IncomeModel>>(), DemoData.sampleIncomes),
      _seedBox<BudgetModel>(sl<Box<BudgetModel>>(), DemoData.sampleBudgets),
      _seedBox<GoalModel>(sl<Box<GoalModel>>(), DemoData.sampleGoals),
      _seedBox<GoalContributionModel>(
        sl<Box<GoalContributionModel>>(),
        DemoData.sampleContributions,
      ),
      _seedBox<RecurringRuleModel>(
        sl<Box<RecurringRuleModel>>(),
        DemoData.sampleRecurringRules,
      ),
    ]);

    final profile = ProfileModel(
      id: E2EMode.userId,
      fullName: E2EMode.fullName,
      currency: E2EMode.currency,
      timezone: E2EMode.timezone,
      email: E2EMode.email,
    );
    await sl<ProfileLocalDataSource>().cacheProfile(profile);

    log.info('[E2EBootstrap] Local test state ready.');
  }

  static Future<void> _seedBox<T extends Object>(
    Box<T> box,
    Iterable<T> values,
  ) {
    return box.putAll({for (final value in values) _extractId(value): value});
  }

  static String _extractId(Object value) {
    switch (value) {
      case ExpenseModel expense:
        return expense.id;
      case AssetAccountModel account:
        return account.id;
      case IncomeModel income:
        return income.id;
      case BudgetModel budget:
        return budget.id;
      case GoalModel goal:
        return goal.id;
      case GoalContributionModel contribution:
        return contribution.id;
      case RecurringRuleModel recurringRule:
        return recurringRule.id;
      default:
        throw StateError(
          '[E2EBootstrap] Unsupported seed model: ${value.runtimeType}',
        );
    }
  }
}
