import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import Pages
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/add_edit_expense_page.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_list_page.dart'; // Corrected path if needed
import 'package:expense_tracker/features/income/presentation/widgets/add_edit_income_page.dart'; // Corrected path if needed
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/add_edit_account_page.dart';

// Import Entities for 'extra' parameter type safety
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

// Import Shell Widget
import 'main_shell.dart';

// Define Navigator Keys for Shell and Root
// Root navigator key manages navigation outside the shell (e.g., modals, full-screen dialogs)
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();
// Keys for each branch's navigator state within the shell
final GlobalKey<NavigatorState> _shellNavigatorKeyDashboard =
    GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorKeyExpenses =
    GlobalKey<NavigatorState>(debugLabel: 'shellExpenses');
final GlobalKey<NavigatorState> _shellNavigatorKeyIncome =
    GlobalKey<NavigatorState>(debugLabel: 'shellIncome');
final GlobalKey<NavigatorState> _shellNavigatorKeyAccounts =
    GlobalKey<NavigatorState>(debugLabel: 'shellAccounts');

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard', // Start on the dashboard tab
    navigatorKey: _rootNavigatorKey, // Use the root key
    debugLogDiagnostics: true, // Enable logs for debugging navigation
    routes: [
      // Define the main layout using StatefulShellRoute
      StatefulShellRoute.indexedStack(
        // Builder provides the shell widget (MainShell)
        builder: (context, state, navigationShell) {
          // The navigationShell is passed to the MainShell to manage
          // navigation between the different branches (tabs).
          return MainShell(navigationShell: navigationShell);
        },
        // Define the branches (tabs) for the bottom navigation
        branches: [
          // --- Branch 1: Dashboard ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyDashboard, // Assign key
            routes: [
              GoRoute(
                path: '/dashboard',
                // Use pageBuilder for custom transitions (NoTransitionPage keeps it simple)
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardPage(), // Root page for this branch
                ),
                // No sub-routes needed for dashboard currently
              ),
            ],
          ),

          // --- Branch 2: Expenses ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyExpenses,
            routes: [
              GoRoute(
                path: '/expenses',
                name: 'expenses_list', // Optional name for reference
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ExpenseListPage(), // Root page for expenses
                ),
                // Define sub-routes accessible FROM the expenses list
                routes: [
                  GoRoute(
                    path: 'add', // Relative path: /expenses/add
                    name: 'add_expense',
                    parentNavigatorKey:
                        _rootNavigatorKey, // Navigate outside the shell? (e.g., as modal) - Change if full screen needed
                    // Use builder for standard page navigation
                    builder: (context, state) => const AddEditExpensePage(),
                  ),
                  GoRoute(
                    path:
                        'edit/:id', // Relative path: /expenses/edit/expense_id
                    name: 'edit_expense',
                    parentNavigatorKey:
                        _rootNavigatorKey, // Navigate outside shell?
                    builder: (context, state) {
                      final expenseId = state.pathParameters['id'];
                      // Safely cast 'extra' which contains the Expense object
                      final expense = state.extra as Expense?;
                      // Pass parameters to the page
                      return AddEditExpensePage(
                          expenseId: expenseId, expense: expense);
                    },
                  ),
                ],
              ),
            ],
          ),

          // --- Branch 3: Income ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyIncome,
            routes: [
              GoRoute(
                path: '/income',
                name: 'income_list',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: IncomeListPage(), // Root page for income
                ),
                routes: [
                  GoRoute(
                    path: 'add', // Relative path: /income/add
                    name: 'add_income',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditIncomePage(),
                  ),
                  GoRoute(
                    path: 'edit/:id', // Relative path: /income/edit/income_id
                    name: 'edit_income',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final incomeId = state.pathParameters['id'];
                      final income = state.extra as Income?;
                      return AddEditIncomePage(
                          incomeId: incomeId, income: income);
                    },
                  ),
                ],
              ),
            ],
          ),

          // --- Branch 4: Accounts ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyAccounts,
            routes: [
              GoRoute(
                path: '/accounts',
                name: 'accounts_list',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AccountListPage(), // Root page for accounts
                ),
                routes: [
                  GoRoute(
                    path: 'add', // Relative path: /accounts/add
                    name: 'add_account',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditAccountPage(),
                  ),
                  GoRoute(
                    path:
                        'edit/:id', // Relative path: /accounts/edit/account_id
                    name: 'edit_account',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final accountId = state.pathParameters['id'];
                      final account = state.extra as AssetAccount?;
                      return AddEditAccountPage(
                          accountId: accountId, account: account);
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
    // Define a simple error page for unmatched routes
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
          child: Text('Error: ${state.error?.message ?? 'Route not found'}')),
    ),
  );
}
