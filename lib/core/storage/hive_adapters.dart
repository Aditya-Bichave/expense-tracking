import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
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
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:hive_ce/hive.dart';

class HiveAdapters {
  static void registerAll() {
    _register(ExpenseModelAdapter());
    _register(AssetAccountModelAdapter());
    _register(IncomeModelAdapter());
    _register(CategoryModelAdapter());
    _register(UserHistoryRuleModelAdapter());
    _register(BudgetModelAdapter());
    _register(GoalModelAdapter());
    _register(GoalContributionModelAdapter());
    _register(RecurringRuleModelAdapter());
    _register(RecurringRuleAuditLogModelAdapter());
    _register(SyncMutationModelAdapter());
    _register(OpTypeAdapter());
    _register(SyncStatusAdapter());
    _register(GroupModelAdapter());
    _register(GroupMemberModelAdapter());
    _register(GroupExpenseModelAdapter());
    _register(ExpensePayerModelAdapter());
    _register(ExpenseSplitModelAdapter());
    _register(ProfileModelAdapter());
  }

  static void _register<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }
}
