// lib/core/constants/route_names.dart
abstract class RouteNames {
  // --- Shell Root Paths ---
  static const String dashboard = '/dashboard';
  static const String transactionsList = '/transactions';
  static const String budgetsAndCats =
      '/budgets-cats'; // Entry point for the tab
  static const String accounts = '/accounts';
  static const String settings = '/settings';

  // --- Transaction Sub-Routes ---
  static const String addTransaction = 'add';
  static const String editTransaction = 'edit';
  static const String transactionDetail = 'transaction_detail';

  // --- Budgets & Cats Sub-Routes ---

  // --- Budget Routes (Directly under budgetsAndCats for simplicity in GoRouter setup) ---
  static const String createBudget = 'creat_budget';
  static const String addBudget = 'add_budget';
  static const String editBudget = 'edit_budget'; // <<< DEFINED HERE
  static const String budgetDetail = 'budget_detail'; // <<< DEFINED HERE

  // --- Category Routes (Nested under budgetsAndCats logically, but path structure matters) ---
  // Path: /budgets-cats/manage_categories
  static const String manageCategories = 'manage_categories';
  // Path: /budgets-cats/manage_categories/add_category
  static const String addCategory = 'add_category';
  // Path: /budgets-cats/manage_categories/edit_category/:id
  static const String editCategory = 'edit_category';

  // --- Goal Routes (Directly under budgetsAndCats for simplicity) ---
  static const String addGoal = 'add_goal'; // <<< DEFINED HERE
  static const String editGoal = 'edit_goal'; // <<< DEFINED HERE
  static const String goalDetail = 'goal_detail'; // <<< DEFINED HERE

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

  // --- Parameter Names ---
  static const String paramId =
      'id'; // Used by editBudget, editCategory, editGoal, goalDetail, budgetDetail
  static const String paramAccountId = 'accountId';
  static const String paramTransactionId = 'transactionId';
}
