import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart'; // Import logger

// Import Pages
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/add_edit_expense_page.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_list_page.dart'; // Correct path now
import 'package:expense_tracker/features/income/presentation/widgets/add_edit_income_page.dart'; // Correct path now
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/add_edit_account_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';

// Import Entities for 'extra' parameter type safety
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

// Import Shell Widget
import 'main_shell.dart'; // Assuming main_shell.dart is in lib/

// Define Navigator Keys for Shell and Root
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
// Keys for each branch's navigator state within the shell
final GlobalKey<NavigatorState> _shellNavigatorKeyDashboard =
    GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorKeyExpenses =
    GlobalKey<NavigatorState>(debugLabel: 'shellExpenses');
final GlobalKey<NavigatorState> _shellNavigatorKeyIncome =
    GlobalKey<NavigatorState>(debugLabel: 'shellIncome');
final GlobalKey<NavigatorState> _shellNavigatorKeyAccounts =
    GlobalKey<NavigatorState>(debugLabel: 'shellAccounts');
final GlobalKey<NavigatorState> _shellNavigatorKeySettings =
    GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/dashboard', // Start on the dashboard tab
    navigatorKey: _rootNavigatorKey, // Use the root key
    debugLogDiagnostics: true, // Enable GoRouter's internal logs

    // CORRECT: Global observers go here
    observers: [
      GoRouterObserver(), // Add global observer for logging
    ],

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
                // REMOVED observers: [GoRouterObserver(location: '/dashboard')],
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
                // REMOVED observers: [GoRouterObserver(location: '/expenses')],
                routes: [
                  GoRoute(
                    path: 'add', // Relative path: /expenses/add
                    name: 'add_expense',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditExpensePage(),
                    // REMOVED observers: [GoRouterObserver(location: '/expenses/add')],
                  ),
                  GoRoute(
                    path:
                        'edit/:id', // Relative path: /expenses/edit/expense_id
                    name: 'edit_expense',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final expenseId = state.pathParameters['id'];
                      final expense = state.extra as Expense?;
                      log.info(
                          "Navigating to edit_expense: ID=$expenseId, Expense provided=${expense != null}");
                      if (expense == null || expenseId == null) {
                        log.warning(
                            "Edit expense route missing required parameters. ID=$expenseId, Extra=${state.extra}");
                      }
                      return AddEditExpensePage(
                          expenseId: expenseId, expense: expense);
                    },
                    // REMOVED observers: [GoRouterObserver(location: '/expenses/edit')],
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
                // REMOVED observers: [GoRouterObserver(location: '/income')],
                routes: [
                  GoRoute(
                    path: 'add', // Relative path: /income/add
                    name: 'add_income',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditIncomePage(),
                    // REMOVED observers: [GoRouterObserver(location: '/income/add')],
                  ),
                  GoRoute(
                    path: 'edit/:id', // Relative path: /income/edit/income_id
                    name: 'edit_income',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final incomeId = state.pathParameters['id'];
                      final income = state.extra as Income?;
                      log.info(
                          "Navigating to edit_income: ID=$incomeId, Income provided=${income != null}");
                      if (income == null || incomeId == null) {
                        log.warning(
                            "Edit income route missing required parameters. ID=$incomeId, Extra=${state.extra}");
                      }
                      return AddEditIncomePage(
                          incomeId: incomeId, income: income);
                    },
                    // REMOVED observers: [GoRouterObserver(location: '/income/edit')],
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
                // REMOVED observers: [GoRouterObserver(location: '/accounts')],
                routes: [
                  GoRoute(
                    path: 'add', // Relative path: /accounts/add
                    name: 'add_account',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditAccountPage(),
                    // REMOVED observers: [GoRouterObserver(location: '/accounts/add')],
                  ),
                  GoRoute(
                    path:
                        'edit/:id', // Relative path: /accounts/edit/account_id
                    name: 'edit_account',
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final accountId = state.pathParameters['id'];
                      final account = state.extra as AssetAccount?;
                      log.info(
                          "Navigating to edit_account: ID=$accountId, Account provided=${account != null}");
                      if (account == null || accountId == null) {
                        log.warning(
                            "Edit account route missing required parameters. ID=$accountId, Extra=${state.extra}");
                      }
                      return AddEditAccountPage(
                          accountId: accountId, account: account);
                    },
                    // REMOVED observers: [GoRouterObserver(location: '/accounts/edit')],
                  ),
                ],
              ),
            ],
          ),

          // --- Branch 5: Settings ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeySettings,
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsPage(),
                ),
                // REMOVED observers: [GoRouterObserver(location: '/settings')],
              ),
            ],
          ),
        ],
      ),
    ],

    // Define a simple error page for unmatched routes
    errorBuilder: (context, state) {
      log.severe(
          "GoRouter error: Path '${state.uri}' not found. Error: ${state.error}");
      return Scaffold(
        appBar: AppBar(title: const Text('Page Not Found')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Error: The requested page (${state.uri}) could not be found.\n${state.error?.message ?? ''}',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      );
    }, // <-- Added missing comma here
  ); // <-- Added missing parenthesis here
}

// Simple observer for logging route changes
class GoRouterObserver extends NavigatorObserver {
  // Removed optional location parameter as it's not needed for global observer
  // final String? location;
  // GoRouterObserver({this.location});

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    // Use route.settings.name or route details from GoRouter state if needed
    log.info(
        'GoRouter: Pushed route: ${route.settings.name ?? route.settings.toString()}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.info(
        'GoRouter: Popped route: ${route.settings.name ?? route.settings.toString()}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.info(
        'GoRouter: Removed route: ${route.settings.name ?? route.settings.toString()}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    log.info(
        'GoRouter: Replaced route: ${oldRoute?.settings.name ?? oldRoute?.settings.toString()} with ${newRoute?.settings.name ?? newRoute?.settings.toString()}');
  }
}
