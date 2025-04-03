// lib/core/constants/route_names.dart

abstract class RouteNames {
  // Shell Root Paths (match router paths)
  static const String dashboard = '/dashboard';
  static const String expensesList = '/expenses';
  static const String incomeList = '/income';
  static const String accountsList = '/accounts';
  static const String settings = '/settings';

  // Detail/Edit Routes (match router names)
  static const String addExpense = 'add_expense';
  static const String editExpense = 'edit_expense';
  static const String addIncome = 'add_income';
  static const String editIncome = 'edit_income';
  static const String addAccount = 'add_account';
  static const String editAccount = 'edit_account';

  // Parameter Names (used in router path definitions)
  static const String paramId = 'id';
}
