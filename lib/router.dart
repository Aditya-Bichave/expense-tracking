// lib/router.dart
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:expense_tracker/main.dart'; // Import logger

// --- Import Pages/Screens ---
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/accounts_tab_page.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/features/expenses/presentation/pages/add_edit_expense_page.dart';
import 'package:expense_tracker/features/income/presentation/widgets/add_edit_income_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/add_edit_account_page.dart';
import 'package:expense_tracker/features/categories/presentation/pages/category_management_screen.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_detail_page.dart';

// Import Placeholder Screen
import 'package:expense_tracker/core/widgets/placeholder_screen.dart';

// Import Shell Widget
import 'main_shell.dart';

// Import Route Names constants
import 'package:expense_tracker/core/constants/route_names.dart';

// Import Entities for 'extra' parameter type safety
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';

// --- Navigator Keys ---
final GlobalKey<NavigatorState> _rootNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'root');
final GlobalKey<NavigatorState> _shellNavigatorKeyDashboard =
    GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorKeyTransactions =
    GlobalKey<NavigatorState>(debugLabel: 'shellTransactions');
final GlobalKey<NavigatorState> _shellNavigatorKeyBudgetsCats =
    GlobalKey<NavigatorState>(debugLabel: 'shellBudgetsCats');
final GlobalKey<NavigatorState> _shellNavigatorKeyAccounts =
    GlobalKey<NavigatorState>(debugLabel: 'shellAccounts');
final GlobalKey<NavigatorState> _shellNavigatorKeySettings =
    GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

// --- Router Configuration ---
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.dashboard,
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: kDebugMode, // Only log in debug mode
    observers: [GoRouterObserver()],

    routes: [
      // --- Main Application Shell ---
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          // --- Branch 0: Dashboard ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyDashboard,
            routes: [
              GoRoute(
                path: RouteNames.dashboard,
                name: RouteNames.dashboard,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: DashboardPage()),
              ),
            ],
          ),

          // --- Branch 1: Transactions ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyTransactions,
            routes: [
              GoRoute(
                path: RouteNames.transactionsList,
                name: RouteNames.transactionsList,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TransactionListPage()),
                routes: [
                  // Add/Edit/Detail Routes (Pushed onto Root Navigator)
                  GoRoute(
                    path: RouteNames.addExpense,
                    name: RouteNames.addExpense,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditExpensePage(),
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.editExpense}/:${RouteNames.paramTransactionId}',
                    name: RouteNames.editExpense,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildEditExpensePage,
                  ),
                  GoRoute(
                    path: RouteNames.addIncome,
                    name: RouteNames.addIncome,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditIncomePage(),
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.editIncome}/:${RouteNames.paramTransactionId}',
                    name: RouteNames.editIncome,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildEditIncomePage,
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.transactionDetail}/:${RouteNames.paramTransactionId}',
                    name: RouteNames.transactionDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildTransactionDetailPage,
                  ),
                ],
              ),
            ],
          ),

          // --- Branch 2: Budgets & Cats ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyBudgetsCats,
            routes: [
              GoRoute(
                  path: RouteNames.budgetsAndCats,
                  name: RouteNames.budgetsAndCats,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: BudgetsAndCatsTabPage()),
                  routes: [
                    GoRoute(
                        path: RouteNames.manageCategories,
                        name: RouteNames.manageCategories,
                        builder: (context, state) =>
                            const CategoryManagementScreen(),
                        routes: [
                          GoRoute(
                            path: RouteNames.addCategory,
                            name: RouteNames.addCategory,
                            parentNavigatorKey: _rootNavigatorKey,
                            builder: (context, state) =>
                                const AddEditCategoryScreen(),
                          ),
                          GoRoute(
                            path:
                                '${RouteNames.editCategory}/:${RouteNames.paramId}',
                            name: RouteNames.editCategory,
                            parentNavigatorKey: _rootNavigatorKey,
                            builder: _buildEditCategoryPage,
                          ),
                        ]),
                    GoRoute(
                      path: RouteNames.createBudget,
                      name: RouteNames.createBudget,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          const PlaceholderScreen(featureName: 'Create Budget'),
                    ),
                  ]),
            ],
          ),

          // --- Branch 3: Accounts ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyAccounts,
            routes: [
              GoRoute(
                path: RouteNames.accounts,
                name: RouteNames.accounts,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AccountsTabPage()),
                routes: [
                  GoRoute(
                    path: RouteNames.addAccount,
                    name: RouteNames.addAccount,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditAccountPage(),
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.editAccount}/:${RouteNames.paramAccountId}',
                    name: RouteNames.editAccount,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildEditAccountPage,
                  ),
                  GoRoute(
                    path: RouteNames.addLiabilityAccount,
                    name: RouteNames.addLiabilityAccount,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PlaceholderScreen(
                        featureName: 'Add Liability Account'),
                  ),
                  GoRoute(
                      path:
                          '${RouteNames.accountDetail}/:${RouteNames.paramAccountId}',
                      name: RouteNames.accountDetail,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        final id =
                            state.pathParameters[RouteNames.paramAccountId];
                        return PlaceholderScreen(
                            featureName:
                                'Account Details - ID: ${id ?? 'Unknown'}');
                      }),
                ],
              ),
            ],
          ),

          // --- Branch 4: Settings ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeySettings,
            routes: [
              GoRoute(
                  path: RouteNames.settings,
                  name: RouteNames.settings,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: SettingsPage()),
                  routes: [
                    // Placeholder routes pushed onto root
                    GoRoute(
                        path: RouteNames.settingsProfile,
                        name: RouteNames.settingsProfile,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) => const PlaceholderScreen(
                            featureName: 'Profile Settings')),
                    GoRoute(
                        path: RouteNames.settingsSecurity,
                        name: RouteNames.settingsSecurity,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) => const PlaceholderScreen(
                            featureName: 'Security Settings')),
                    GoRoute(
                        path: RouteNames.settingsAppearance,
                        name: RouteNames.settingsAppearance,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) => const PlaceholderScreen(
                            featureName: 'Appearance Settings')),
                    GoRoute(
                        path: RouteNames.settingsNotifications,
                        name: RouteNames.settingsNotifications,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) => const PlaceholderScreen(
                            featureName: 'Notification Settings')),
                    GoRoute(
                        path: RouteNames.settingsConnections,
                        name: RouteNames.settingsConnections,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) => const PlaceholderScreen(
                            featureName: 'Connections / Shared Space')),
                    GoRoute(
                        path: RouteNames.settingsExport,
                        name: RouteNames.settingsExport,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) => const PlaceholderScreen(
                            featureName: 'Export Data')),
                    GoRoute(
                        path: RouteNames.settingsTrash,
                        name: RouteNames.settingsTrash,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) =>
                            const PlaceholderScreen(featureName: 'Trash Bin')),
                    GoRoute(
                        path: RouteNames.settingsFeedback,
                        name: RouteNames.settingsFeedback,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) => const PlaceholderScreen(
                            featureName: 'Send Feedback')),
                    GoRoute(
                        path: RouteNames.settingsAbout,
                        name: RouteNames.settingsAbout,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (c, s) =>
                            const PlaceholderScreen(featureName: 'About App')),
                  ]),
            ],
          ),
        ],
      ),
    ],

    // --- Error Handling ---
    errorBuilder: (context, state) {
      log.severe(
          "[AppRouter] Error - Path: '${state.uri}', Error: ${state.error}");
      return Scaffold(/* ... Error Page UI ... */);
    },
  );

  // --- Helper Builders for Routes Requiring Data ---
  // These handle extracting params/extra and logging errors if data is missing

  static Widget _buildEditExpensePage(
      BuildContext context, GoRouterState state) {
    final expenseId = state.pathParameters[RouteNames.paramTransactionId];
    final expense = state.extra as Expense?;
    log.info(
        "[AppRouter] Building edit_expense: ID=$expenseId, Expense provided=${expense != null}");
    if (expenseId == null) {
      log.severe("Edit Expense route called without transaction ID!");
      return const Scaffold(
          body: Center(child: Text("Error: Missing Expense ID")));
    }
    return AddEditExpensePage(expenseId: expenseId, expense: expense);
  }

  static Widget _buildEditIncomePage(
      BuildContext context, GoRouterState state) {
    final incomeId = state.pathParameters[RouteNames.paramTransactionId];
    final income = state.extra as Income?;
    log.info(
        "[AppRouter] Building edit_income: ID=$incomeId, Income provided=${income != null}");
    if (incomeId == null) {
      log.severe("Edit Income route called without transaction ID!");
      return const Scaffold(
          body: Center(child: Text("Error: Missing Income ID")));
    }
    return AddEditIncomePage(incomeId: incomeId, income: income);
  }

  static Widget _buildTransactionDetailPage(
      BuildContext context, GoRouterState state) {
    final id = state.pathParameters[RouteNames.paramTransactionId];
    TransactionEntity? transaction;
    if (state.extra is TransactionEntity) {
      transaction = state.extra as TransactionEntity;
    } else {
      log.warning(
          "[AppRouter] Transaction Detail route received 'extra' of unexpected type or null. Extra: ${state.extra?.runtimeType}");
      // Potentially fetch based on ID here as a fallback
    }

    if (id == null || transaction == null) {
      log.severe(
          "Transaction Detail route missing ID or valid transaction data!");
      return Scaffold(
          appBar: AppBar(),
          body: const Center(
              child: Text("Error: Could not load transaction details")));
    }
    return TransactionDetailPage(transaction: transaction);
  }

  static Widget _buildEditCategoryPage(
      BuildContext context, GoRouterState state) {
    final categoryId = state.pathParameters[RouteNames.paramId];
    final category = state.extra as Category?;
    log.info(
        "[AppRouter] Building edit_category: ID=$categoryId, Category provided=${category != null}");
    if (categoryId == null) {
      log.severe("Edit Category route called without ID!");
      return const Scaffold(
          body: Center(child: Text("Error: Missing Category ID")));
    }
    return AddEditCategoryScreen(
        initialCategory:
            category); // Edit screen handles null category for add case if needed
  }

  static Widget _buildEditAccountPage(
      BuildContext context, GoRouterState state) {
    final accountId = state.pathParameters[RouteNames.paramAccountId];
    final account = state.extra as AssetAccount?; // Assumes Asset for now
    log.info(
        "[AppRouter] Building edit_account: ID=$accountId, Account provided=${account != null}");
    if (accountId == null) {
      log.severe("Edit Account route called without ID!");
      return const Scaffold(
          body: Center(child: Text("Error: Missing Account ID")));
    }
    return AddEditAccountPage(accountId: accountId, account: account);
  }
}

// --- GoRouter Observer for Logging ---
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.fine(
        'GoRouter Pushed: ${route.settings.name ?? route.settings.arguments?.toString() ?? route.toString()} '
        '<- ${previousRoute?.settings.name ?? previousRoute?.settings.arguments?.toString() ?? 'null'}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.fine(
        'GoRouter Popped: ${route.settings.name ?? route.settings.arguments?.toString() ?? route.toString()} '
        '-> ${previousRoute?.settings.name ?? previousRoute?.settings.arguments?.toString() ?? 'null'}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    log.fine(
        'GoRouter Removed: ${route.settings.name ?? route.settings.arguments?.toString() ?? route.toString()}');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    log.fine(
        'GoRouter Replaced: ${oldRoute?.settings.name ?? oldRoute?.settings.arguments?.toString() ?? 'null'} '
        'with ${newRoute?.settings.name ?? newRoute?.settings.arguments?.toString() ?? 'null'}');
  }
}

// Helper extension (if not already in utils)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
