/// On-disk Hive box names.
///
/// These are the names the shipped app has always opened, so they double as the
/// on-disk file names for existing installs. Renaming a value here does not
/// migrate anything — it points the app at a *different* box and silently
/// orphans the user's data. Treat every string below as a storage contract.
///
/// Note: [HiveConstants] in `core/constants/hive_constants.dart` declares a
/// second, divergent set of names that no shipped code path has ever used. Do
/// not "unify" the two without a real migration; see the storage backlog.
abstract final class HiveBoxNames {
  static const String expenses = 'expenses';
  static const String accounts = 'accounts';
  static const String income = 'income';
  static const String categories = 'categories';
  static const String userHistoryRules = 'user_history_rules';
  static const String budgets = 'budgets';
  static const String goals = 'goals';
  static const String goalContributions = 'goal_contributions';
  static const String recurringRules = 'recurring_rules';
  static const String recurringRuleAuditLogs = 'recurring_rule_audit_logs';
  static const String syncOutbox = 'sync_outbox';
  static const String groups = 'groups';
  static const String groupMembers = 'group_members';
  static const String groupExpenses = 'group_expenses';
  static const String profile = 'profile';
}
