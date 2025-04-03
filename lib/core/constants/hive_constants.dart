// lib/core/constants/hive_constants.dart

abstract class HiveConstants {
  static const String expenseBoxName = 'expenses';
  static const String accountBoxName = 'asset_accounts';
  static const String incomeBoxName = 'incomes';
  // --- ADDED ---
  static const String categoryBoxName = 'categories_v1'; // Add versioning
  static const String userHistoryRuleBoxName =
      'user_history_rules_v1'; // Add versioning
  // Add other box names here if created later
}
