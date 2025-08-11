// lib/core/constants/hive_constants.dart
abstract class HiveConstants {
  static const String expenseBoxName = 'expenses';
  static const String accountBoxName = 'asset_accounts';
  static const String incomeBoxName = 'incomes';
  static const String categoryBoxName = 'categories_v1';
  static const String userHistoryRuleBoxName = 'user_history_rules_v1';
  static const String budgetBoxName = 'budgets_v1';
  // --- ADDED GOAL/CONTRIBUTION BOX NAMES ---
  static const String goalBoxName = 'goals_v1';
  static const String goalContributionBoxName = 'goal_contributions_v1';

  // --- Recurring Transactions ---
  static const String recurringRuleBoxName = 'recurring_rules_v1';
  static const String recurringRuleAuditLogBoxName = 'recurring_rule_audit_logs_v1';
}
