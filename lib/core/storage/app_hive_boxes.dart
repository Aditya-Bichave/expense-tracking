import 'package:expense_tracker/core/storage/hive_box_names.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
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
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

/// Every Hive box the app keeps open for its whole lifetime.
///
/// Bundling them keeps the 17 model imports and the box-opening details out of
/// the entrypoint, and gives the service locator a single value to destructure.
class AppHiveBoxes {
  const AppHiveBoxes({
    required this.expenseBox,
    required this.accountBox,
    required this.incomeBox,
    required this.categoryBox,
    required this.userHistoryBox,
    required this.budgetBox,
    required this.goalBox,
    required this.contributionBox,
    required this.recurringRuleBox,
    required this.recurringRuleAuditLogBox,
    required this.outboxBox,
    required this.groupBox,
    required this.groupMemberBox,
    required this.groupExpenseBox,
    required this.profileBox,
  });

  final Box<ExpenseModel> expenseBox;
  final Box<AssetAccountModel> accountBox;
  final Box<IncomeModel> incomeBox;
  final Box<CategoryModel> categoryBox;
  final Box<UserHistoryRuleModel> userHistoryBox;
  final Box<BudgetModel> budgetBox;
  final Box<GoalModel> goalBox;
  final Box<GoalContributionModel> contributionBox;
  final Box<RecurringRuleModel> recurringRuleBox;
  final Box<RecurringRuleAuditLogModel> recurringRuleAuditLogBox;
  final Box<SyncMutationModel> outboxBox;
  final Box<GroupModel> groupBox;
  final Box<GroupMemberModel> groupMemberBox;
  final Box<GroupExpenseModel> groupExpenseBox;
  final Box<ProfileModel> profileBox;

  /// Opens every box encrypted with [encryptionKey].
  ///
  /// All opens are started before the first `await` so they proceed
  /// concurrently; startup pays the cost of the slowest box, not the sum.
  ///
  /// Every box is encrypted. Opening any one of them without the cipher — or
  /// with a different key — makes that box unreadable, so the cipher is built
  /// once here and applied uniformly.
  static Future<AppHiveBoxes> open(List<int> encryptionKey) async {
    log.info('Opening Hive boxes...');
    final cipher = HiveAesCipher(encryptionKey);

    Future<Box<T>> openBox<T>(String name) =>
        Hive.openBox<T>(name, encryptionCipher: cipher);

    final expense = openBox<ExpenseModel>(HiveBoxNames.expenses);
    final account = openBox<AssetAccountModel>(HiveBoxNames.accounts);
    final income = openBox<IncomeModel>(HiveBoxNames.income);
    final category = openBox<CategoryModel>(HiveBoxNames.categories);
    final userHistory = openBox<UserHistoryRuleModel>(
      HiveBoxNames.userHistoryRules,
    );
    final budget = openBox<BudgetModel>(HiveBoxNames.budgets);
    final goal = openBox<GoalModel>(HiveBoxNames.goals);
    final contribution = openBox<GoalContributionModel>(
      HiveBoxNames.goalContributions,
    );
    final recurringRule = openBox<RecurringRuleModel>(
      HiveBoxNames.recurringRules,
    );
    final recurringRuleAuditLog = openBox<RecurringRuleAuditLogModel>(
      HiveBoxNames.recurringRuleAuditLogs,
    );
    final outbox = openBox<SyncMutationModel>(HiveBoxNames.syncOutbox);
    final group = openBox<GroupModel>(HiveBoxNames.groups);
    final groupMember = openBox<GroupMemberModel>(HiveBoxNames.groupMembers);
    final groupExpense = openBox<GroupExpenseModel>(HiveBoxNames.groupExpenses);
    final profile = openBox<ProfileModel>(HiveBoxNames.profile);

    final boxes = AppHiveBoxes(
      expenseBox: await expense,
      accountBox: await account,
      incomeBox: await income,
      categoryBox: await category,
      userHistoryBox: await userHistory,
      budgetBox: await budget,
      goalBox: await goal,
      contributionBox: await contribution,
      recurringRuleBox: await recurringRule,
      recurringRuleAuditLogBox: await recurringRuleAuditLog,
      outboxBox: await outbox,
      groupBox: await group,
      groupMemberBox: await groupMember,
      groupExpenseBox: await groupExpense,
      profileBox: await profile,
    );

    log.info('All Hive boxes opened.');
    return boxes;
  }
}
