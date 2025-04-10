// lib/core/constants/route_names.dart
abstract class RouteNames {
  // --- Shell Root Paths ---
  static const String dashboard = '/dashboard';
  static const String transactionsList = '/transactions';
  static const String budgetsAndCats = '/budgets-cats';
  static const String accounts = '/accounts';
  static const String settings = '/settings';
  static const String reports = '/reports'; // Keep this if using a shell later

  // --- Transaction Sub-Routes ---
  static const String addTransaction = 'add';
  static const String editTransaction = 'edit';
  static const String transactionDetail = 'transaction_detail';

  // --- Budgets & Cats Sub-Routes ---
  static const String addBudget = 'add_budget';
  static const String editBudget = 'edit_budget';
  static const String budgetDetail = 'budget_detail';
  static const String manageCategories = 'manage_categories';
  static const String addCategory = 'add_category';
  static const String editCategory = 'edit_category';
  static const String addGoal = 'add_goal';
  static const String editGoal = 'edit_goal';
  static const String goalDetail = 'goal_detail';

  // --- Accounts Sub-Routes ---
  static const String addAccount = 'add_account';
  static const String editAccount = 'edit_account';
  static const String accountDetail = 'account_detail';
  static const String addLiabilityAccount = 'add_liability_account';

  // --- Settings Sub-Routes ---
  static const String settingsProfile = 'settings_profile';
  static const String settingsSecurity = 'settings_security';
  static const String settingsAppearance = 'settings_appearance';
  static const String settingsNotifications = 'settings_notifications';
  static const String settingsConnections = 'settings_connections';
  static const String settingsExport = 'settings_export';
  static const String settingsTrash = 'settings_trash';
  static const String settingsFeedback = 'settings_feedback';
  static const String settingsAbout = 'settings_about';

  // --- Report Sub-Routes (Now directly under root or dashboard) ---
  static const String reportSpendingCategory =
      'spending_category'; // Path: /dashboard/spending_category
  static const String reportSpendingTime =
      'spending_time'; // Path: /dashboard/spending_time
  static const String reportIncomeExpense =
      'income_expense'; // Path: /dashboard/income_expense
  // --- ADDED Report Routes ---
  static const String reportBudgetPerformance =
      'budget_performance'; // Path: /dashboard/budget_performance
  static const String reportGoalProgress =
      'goal_progress'; // Path: /dashboard/goal_progress
  // static const String reportNetWorth = 'net_worth'; // Keep commented out

  // --- Parameter Names ---
  static const String paramId = 'id';
  static const String paramAccountId = 'accountId';
  static const String paramTransactionId = 'transactionId';
  // --- ADDED Parameter Names ---
  static const String paramBudgetId =
      'budgetId'; // Optional param for budget report
  static const String paramGoalId = 'goalId'; // Optional param for goal report
}
