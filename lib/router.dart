import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Import Pages
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/add_edit_expense_page.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_list_page.dart'; // Check path
import 'package:expense_tracker/features/income/presentation/widgets/add_edit_income_page.dart'; // Check path
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/add_edit_account_page.dart';
// --- Settings Page Import ---
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
// --- End Settings Page Import ---

// Import Entities for 'extra' parameter type safety
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

// Import Shell Widget
import 'main_shell.dart'; // Assuming main_shell.dart is in lib/

// Define Navigator Keys for Shell and Root
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
// --- Settings Navigator Key ---
final GlobalKey<NavigatorState> _shellNavigatorKeySettings =
    GlobalKey<NavigatorState>(debugLabel: 'shellSettings');
// --- End Settings Navigator Key ---

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard', // Start on the dashboard tab
    navigatorKey: _rootNavigatorKey, // Use the root key
    debugLogDiagnostics: true, // Enable logs for debugging navigation
    routes: [
      // Define the main layout using StatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // Pass the navigationShell to MainShell
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // --- Branch 1: Dashboard ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyDashboard,
            routes: [
              GoRoute(
                path: '/dashboard',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: DashboardPage(),
                ),
              ),
            ],
          ),

          // --- Branch 2: Expenses ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyExpenses,
            routes: [
              GoRoute(
                path: '/expenses',
                name: 'expenses_list',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ExpenseListPage(),
                ),
                routes: [
                  GoRoute(
                    path: 'add', // Relative path: /expenses/add
                    name: 'add_expense',
                    parentNavigatorKey:
                        _rootNavigatorKey, // Navigate using root (e.g., for modal or full screen)
                    builder: (context, state) => const AddEditExpensePage(),
                  ),
                  GoRoute(
                    path:
                        'edit/:id', // Relative path: /expenses/edit/expense_id
                    name: 'edit_expense',
                    parentNavigatorKey:
                        _rootNavigatorKey, // Navigate using root
                    builder: (context, state) {
                      // Extract parameters
                      final expenseId = state.pathParameters['id'];
                      final expense = state.extra
                          as Expense?; // Passed via context.push extra
                      // Return the page with parameters
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
                  child: IncomeListPage(),
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
                  child: AccountListPage(),
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

          // --- Branch 5: Settings (New) ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeySettings, // Assign the new key
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings', // Optional name
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsPage(), // The root page for the settings tab
                ),
                // Add sub-routes here if needed later (e.g., /settings/profile)
              ),
            ],
          ),
          // --- End Branch 5: Settings ---
        ],
      ),
      // Optional: Routes outside the shell (e.g., Login) can be defined here
      // GoRoute(path: '/login', builder: (context, state) => LoginPage()),
    ],
    // Define a simple error page for unmatched routes
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
          child: Text('Error: ${state.error?.message ?? 'Route not found'}')),
    ),
  );
}
