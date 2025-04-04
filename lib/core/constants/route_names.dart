// lib/core/constants/route_names.dart

abstract class RouteNames {
  // --- Shell Root Paths (match GoRouter paths for branches) ---
  static const String dashboard = '/dashboard';
  static const String transactionsList = '/transactions';
  static const String budgetsAndCats = '/budgets-cats'; // New combined tab
  static const String accounts =
      '/accounts'; // Renamed from accountsList for clarity
  static const String settings = '/settings';

  // --- Transaction Sub-Routes ---
  // Reusing existing expense/income routes, assuming they will be adapted or replaced later
  static const String addExpense =
      'add_expense'; // Relative to transactionsList? Or keep top-level? Decide during Transaction Tab refactor. For now, keep accessible.
  static const String editExpense = 'edit_expense';
  static const String addIncome = 'add_income';
  static const String editIncome = 'edit_income';
  static const String transactionDetail =
      'transaction_detail'; // Placeholder for detail view

  // --- Budgets & Cats Sub-Routes ---
  static const String manageCategories =
      'manage_categories'; // Navigated to from Budgets & Cats Tab
  static const String addCategory =
      'add_category'; // Accessed from Manage Categories Screen
  static const String editCategory =
      'edit_category'; // Accessed from Manage Categories Screen
  static const String createBudget = 'create_budget'; // Placeholder Target

  // --- Accounts Sub-Routes ---
  static const String addAccount = 'add_account'; // Now relative to /accounts
  static const String editAccount = 'edit_account'; // Now relative to /accounts
  static const String accountDetail = 'account_detail'; // Placeholder Target
  static const String addLiabilityAccount =
      'add_liability_account'; // Placeholder Target

  // --- Settings Sub-Routes (Placeholders unless implemented) ---
  static const String settingsProfile = 'settings_profile';
  static const String settingsSecurity = 'settings_security';
  static const String settingsAppearance =
      'settings_appearance'; // Could be inline, but placeholder allows dedicated screen
  static const String settingsNotifications = 'settings_notifications';
  static const String settingsConnections = 'settings_connections';
  static const String settingsExport = 'settings_export';
  static const String settingsTrash = 'settings_trash';
  static const String settingsFeedback = 'settings_feedback';
  static const String settingsAbout = 'settings_about';
  // Note: Backup, Restore, ClearData are actions, not routes typically
  // Note: Legal links might open external browser or dedicated view

  // --- Parameter Names ---
  static const String paramId = 'id'; // Common parameter name
  static const String paramAccountId = 'accountId';
  static const String paramTransactionId = 'transactionId';
}
