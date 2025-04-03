// lib/router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart'; // Import logger

// Import Pages
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/expense_list_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/add_edit_expense_page.dart';
import 'package:expense_tracker/features/income/presentation/widgets/income_list_page.dart';
import 'package:expense_tracker/features/income/presentation/widgets/add_edit_income_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/account_list_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/add_edit_account_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';

// Import Entities for 'extra' parameter type safety
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

// Import Shell Widget
import 'main_shell.dart';

// Import Route Names constants
import 'package:expense_tracker/core/constants/route_names.dart';

// Define Navigator Keys for Shell and Root
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
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
    initialLocation: RouteNames.dashboard, // Use constant
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: true,
    observers: [GoRouterObserver()], // Use the custom observer for logging

    routes: [
      // Main layout using StatefulShellRoute
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // --- Branch 1: Dashboard ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyDashboard,
            routes: [
              GoRoute(
                path: RouteNames.dashboard, // Use constant
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardPage()),
              ),
            ],
          ),

          // --- Branch 2: Expenses ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyExpenses,
            routes: [
              GoRoute(
                path: RouteNames.expensesList, // Use constant
                name: RouteNames
                    .expensesList, // Use constant name if needed elsewhere, matches path here
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: ExpenseListPage()),
                routes: [
                  GoRoute(
                    path: 'add', // Relative path
                    name: RouteNames.addExpense, // Use constant
                    parentNavigatorKey: _rootNavigatorKey, // Show above shell
                    builder: (context, state) => const AddEditExpensePage(),
                  ),
                  GoRoute(
                    path:
                        'edit/:${RouteNames.paramId}', // Use constant for param name
                    name: RouteNames.editExpense, // Use constant
                    parentNavigatorKey: _rootNavigatorKey, // Show above shell
                    builder: (context, state) {
                      final expenseId = state
                          .pathParameters[RouteNames.paramId]; // Use constant
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
                path: RouteNames.incomeList, // Use constant
                name: RouteNames.incomeList, // Use constant name
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: IncomeListPage()),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: RouteNames.addIncome, // Use constant
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditIncomePage(),
                  ),
                  GoRoute(
                    path: 'edit/:${RouteNames.paramId}',
                    name: RouteNames.editIncome, // Use constant
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final incomeId = state.pathParameters[RouteNames.paramId];
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
                path: RouteNames.accountsList, // Use constant
                name: RouteNames.accountsList, // Use constant name
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AccountListPage()),
                routes: [
                  GoRoute(
                    path: 'add',
                    name: RouteNames.addAccount, // Use constant
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditAccountPage(),
                  ),
                  GoRoute(
                    path: 'edit/:${RouteNames.paramId}',
                    name: RouteNames.editAccount, // Use constant
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final accountId =
                          state.pathParameters[RouteNames.paramId];
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
                path: RouteNames.settings, // Use constant
                name: RouteNames.settings, // Use constant name
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsPage()),
              ),
            ],
          ),
        ],
      ),
    ],

    // Error Builder remains the same
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
    },
  );
}

// Simple observer for logging route changes (Keep as before)
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
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
