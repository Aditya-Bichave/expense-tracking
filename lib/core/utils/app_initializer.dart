import 'package:expense_tracker/core/constants/hive_constants.dart';
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

class AppInitializer {
  static void _registerAdapter<T>(TypeAdapter<T> adapter) {
    if (!Hive.isAdapterRegistered(adapter.typeId)) {
      Hive.registerAdapter(adapter);
    }
  }

  static Future<
    ({
      Box<ProfileModel> profileBox,
      Box<ExpenseModel> expenseBox,
      Box<AssetAccountModel> accountBox,
      Box<IncomeModel> incomeBox,
      Box<CategoryModel> categoryBox,
      Box<UserHistoryRuleModel> userHistoryBox,
      Box<BudgetModel> budgetBox,
      Box<GoalModel> goalBox,
      Box<GoalContributionModel> contributionBox,
      Box<RecurringRuleModel> recurringRuleBox,
      Box<RecurringRuleAuditLogModel> recurringRuleAuditLogBox,
      Box<SyncMutationModel> outboxBox,
      Box<GroupModel> groupBox,
      Box<GroupMemberModel> groupMemberBox,
      Box<GroupExpenseModel> groupExpenseBox,
    })
  >
  initHiveBoxes(List<int> encryptionKey) async {
    log.info("Registering Hive Adapters...");
    _registerAdapter(ProfileModelAdapter());
    _registerAdapter(ExpenseModelAdapter());
    _registerAdapter(AssetAccountModelAdapter());
    _registerAdapter(IncomeModelAdapter());
    _registerAdapter(CategoryModelAdapter());
    _registerAdapter(UserHistoryRuleModelAdapter());
    _registerAdapter(BudgetModelAdapter());
    _registerAdapter(GoalModelAdapter());
    _registerAdapter(GoalContributionModelAdapter());
    _registerAdapter(RecurringRuleModelAdapter());
    _registerAdapter(RecurringRuleAuditLogModelAdapter());

    _registerAdapter(SyncMutationModelAdapter());
    _registerAdapter(SyncStatusAdapter());
    _registerAdapter(OpTypeAdapter());

    _registerAdapter(GroupModelAdapter());
    _registerAdapter(GroupMemberModelAdapter());
    _registerAdapter(GroupExpenseModelAdapter());
    _registerAdapter(ExpensePayerModelAdapter());
    _registerAdapter(ExpenseSplitModelAdapter());

    log.info("Opening Hive boxes in parallel...");
    // Initiate all openBox calls concurrently
    final profileBoxFuture = Hive.openBox<ProfileModel>(
      HiveConstants.profileBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final expenseBoxFuture = Hive.openBox<ExpenseModel>(
      HiveConstants.expenseBoxName,
    );
    final accountBoxFuture = Hive.openBox<AssetAccountModel>(
      HiveConstants.accountBoxName,
    );
    final incomeBoxFuture = Hive.openBox<IncomeModel>(
      HiveConstants.incomeBoxName,
    );
    final categoryBoxFuture = Hive.openBox<CategoryModel>(
      HiveConstants.categoryBoxName,
    );
    final userHistoryBoxFuture = Hive.openBox<UserHistoryRuleModel>(
      HiveConstants.userHistoryRuleBoxName,
    );
    final budgetBoxFuture = Hive.openBox<BudgetModel>(
      HiveConstants.budgetBoxName,
    );
    final goalBoxFuture = Hive.openBox<GoalModel>(HiveConstants.goalBoxName);
    final contributionBoxFuture = Hive.openBox<GoalContributionModel>(
      HiveConstants.goalContributionBoxName,
    );
    final recurringRuleBoxFuture = Hive.openBox<RecurringRuleModel>(
      HiveConstants.recurringRuleBoxName,
    );
    final recurringRuleAuditLogBoxFuture =
        Hive.openBox<RecurringRuleAuditLogModel>(
          HiveConstants.recurringRuleAuditLogBoxName,
        );

    final outboxBoxFuture = Hive.openBox<SyncMutationModel>(
      HiveConstants.outboxBoxName,
    );
    final groupBoxFuture = Hive.openBox<GroupModel>(HiveConstants.groupBoxName);
    final groupMemberBoxFuture = Hive.openBox<GroupMemberModel>(
      HiveConstants.groupMemberBoxName,
    );
    final groupExpenseBoxFuture = Hive.openBox<GroupExpenseModel>(
      HiveConstants.groupExpenseBoxName,
    );

    // Wait for all to complete
    final results = await Future.wait([
      profileBoxFuture,
      expenseBoxFuture,
      accountBoxFuture,
      incomeBoxFuture,
      categoryBoxFuture,
      userHistoryBoxFuture,
      budgetBoxFuture,
      goalBoxFuture,
      contributionBoxFuture,
      recurringRuleBoxFuture,
      recurringRuleAuditLogBoxFuture,
      outboxBoxFuture,
      groupBoxFuture,
      groupMemberBoxFuture,
      groupExpenseBoxFuture,
    ]);

    log.info("All Hive boxes opened successfully.");

    return (
      profileBox: results[0] as Box<ProfileModel>,
      expenseBox: results[1] as Box<ExpenseModel>,
      accountBox: results[2] as Box<AssetAccountModel>,
      incomeBox: results[3] as Box<IncomeModel>,
      categoryBox: results[4] as Box<CategoryModel>,
      userHistoryBox: results[5] as Box<UserHistoryRuleModel>,
      budgetBox: results[6] as Box<BudgetModel>,
      goalBox: results[7] as Box<GoalModel>,
      contributionBox: results[8] as Box<GoalContributionModel>,
      recurringRuleBox: results[9] as Box<RecurringRuleModel>,
      recurringRuleAuditLogBox: results[10] as Box<RecurringRuleAuditLogModel>,
      outboxBox: results[11] as Box<SyncMutationModel>,
      groupBox: results[12] as Box<GroupModel>,
      groupMemberBox: results[13] as Box<GroupMemberModel>,
      groupExpenseBox: results[14] as Box<GroupExpenseModel>,
    );
  }
}
