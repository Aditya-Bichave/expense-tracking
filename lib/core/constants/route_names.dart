// lib/core/constants/route_names.dart

abstract class RouteNames {
  // --- Shell Root Paths ---
  static const String dashboard = '/dashboard';
  static const String transactionsList = '/transactions';
  static const String budgetsAndCats = '/budgets-cats';
  static const String accounts = '/accounts';
  static const String settings = '/settings';

  // --- Transaction Sub-Routes ---
  static const String addTransaction = 'add'; // Unified add
  static const String editTransaction = 'edit'; // Unified edit prefix
  static const String transactionDetail = 'transaction_detail';

  // --- REMOVED Specific Expense/Income Routes ---
  // static const String addExpense = 'add_expense';
  // static const String editExpense = 'edit_expense';
  // static const String addIncome = 'add_income';
  // static const String editIncome = 'edit_income';

  // --- Budgets & Cats Sub-Routes ---
  static const String manageCategories = 'manage_categories';
  static const String addCategory = 'add_category';
  static const String editCategory = 'edit_category';
  static const String createBudget = 'create_budget';

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
  static const String paramId = 'id';
  static const String paramAccountId = 'accountId';
  static const String paramTransactionId =
      'transactionId'; // Used by editTransaction
}
