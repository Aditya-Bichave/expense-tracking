// lib/core/constants/route_names.dart
abstract class RouteNames {
  // --- ADDED: Initial Setup Route ---
  static const String initialSetup = '/setup';
  // --- END ADDED ---

  // --- Shell Root Paths (Keep as relative paths for ShellBranch) ---
  static const String dashboard = '/dashboard';
  static const String transactionsList = '/transactions';
  static const String budgetsAndCats = '/plan'; // Renamed for clarity
  static const String accounts = '/accounts';
  static const String settings = '/settings';
  static const String recurring = '/recurring';
  // static const String reports = '/reports'; // Reports are nested now

  // --- Recurring Sub-Routes ---
  static const String addRecurring = 'add_recurring';
  static const String editRecurring = 'edit_recurring';

  // --- Transaction Sub-Routes ---
  static const String addTransaction = 'add';
  static const String editTransaction = 'edit';
  static const String transactionDetail = 'transaction_detail';

  // --- Budgets & Cats Sub-Routes (Under '/plan') ---
  static const String addBudget = 'add_budget';
  static const String editBudget = 'edit_budget';
  static const String budgetDetail = 'budget_detail';
  static const String manageCategories = 'manage_categories';
  static const String addCategory = 'add_category';
  static const String editCategory = 'edit_category';
  static const String addGoal = 'add_goal';
  static const String editGoal = 'edit_goal';
  static const String goalDetail = 'goal_detail';

  // --- Accounts Sub-Routes (Under '/accounts') ---
  static const String addAccount = 'add_account';
  static const String editAccount = 'edit_account';
  static const String addLiability = 'add_liability';
  static const String editLiability = 'edit_liability';
  static const String accountDetail =
      'account_detail'; // Keep for potential future use

  // --- Settings Sub-Routes (Keep if needed, but removed from main nav for now) ---
  // static const String settingsProfile = 'settings_profile';
  // static const String settingsSecurity = 'settings_security';
  // static const String settingsAppearance = 'settings_appearance';
  // static const String settingsNotifications = 'settings_notifications';
  // static const String settingsConnections = 'settings_connections';
  static const String settingsExport = 'settings_export';
  // static const String settingsTrash = 'settings_trash';
  // static const String settingsFeedback = 'settings_feedback';
  // static const String settingsAbout = 'settings_about';

  // --- Report Sub-Routes (Nested under '/dashboard') ---
  static const String reportSpendingCategory = 'spending_category';
  static const String reportSpendingTime = 'spending_time';
  static const String reportIncomeExpense = 'income_expense';
  static const String reportBudgetPerformance = 'budget_performance';
  static const String reportGoalProgress = 'goal_progress';

  // --- Parameter Names (Keep as is) ---
  static const String paramId = 'id';
  static const String paramAccountId = 'accountId';
  static const String paramTransactionId = 'transactionId';
  static const String paramBudgetId = 'budgetId';
  static const String paramGoalId = 'goalId';
}
