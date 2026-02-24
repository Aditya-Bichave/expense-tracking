// lib/core/constants/hive_constants.dart
abstract class HiveConstants {
  static const String profileBoxName = 'profile_box'; // Added constant
  static const String expenseBoxName = 'expenses';
  static const String accountBoxName = 'asset_accounts';
  static const String incomeBoxName = 'incomes';
  static const String categoryBoxName = 'categories_v1';
  static const String userHistoryRuleBoxName = 'user_history_rules_v1';
  static const String budgetBoxName = 'budgets_v1';
  static const String goalBoxName = 'goals_v1';
  static const String goalContributionBoxName = 'goal_contributions_v1';
  static const String recurringRuleBoxName = 'recurring_rules_v1';
  static const String recurringRuleAuditLogBoxName =
      'recurring_rule_audit_logs_v1';

  // --- Sync/Outbox ---
  static const String outboxBoxName = 'sync_outbox_v1';
  static const String groupBoxName = 'groups_v1';
  static const String groupMemberBoxName = 'group_members_v1';
  static const String groupExpenseBoxName = 'group_expenses_v1';
  static const String settlementBoxName = 'settlements_v1';

  static const int dataVersion = 1;
  static const String dataVersionKey = 'hive_data_version';
}
