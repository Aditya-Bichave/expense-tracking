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
// --- Import New Unified Page ---
import 'package:expense_tracker/features/transactions/presentation/pages/add_edit_transaction_page.dart';
// --- Import Other Pages ---
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
// No longer need specific Expense/Income here as AddEditTransactionPage handles dynamic data
// import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
// import 'package:expense_tracker/features/income/domain/entities/income.dart';
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
    debugLogDiagnostics: kDebugMode,
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
                path: RouteNames.transactionsList, // Base path: /transactions
                name: RouteNames.transactionsList,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: TransactionListPage()),
                routes: [
                  // --- UPDATED: Unified Add Route ---
                  GoRoute(
                      path: RouteNames
                          .addTransaction, // Relative path: add -> /transactions/add
                      name: RouteNames.addTransaction,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        log.info("[AppRouter] Building Add Transaction page.");
                        // Pass null for initial data when adding
                        return const AddEditTransactionPage(
                            initialTransactionData: null);
                      }),
                  // --- UPDATED: Unified Edit Route ---
                  GoRoute(
                      // Match pattern for editing either type
                      path:
                          '${RouteNames.editTransaction}/:${RouteNames.paramTransactionId}', // Relative: edit/:id -> /transactions/edit/:id
                      name: RouteNames.editTransaction,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) {
                        log.info(
                            "[AppRouter] Attempting to build Edit Transaction page.");
                        log.info(
                            "[AppRouter] Path params: ${state.pathParameters}");
                        log.info(
                            "[AppRouter] Extra data type: ${state.extra?.runtimeType}");

                        final transactionId =
                            state.pathParameters[RouteNames.paramTransactionId];
                        final initialData = state.extra; // Keep it dynamic

                        if (transactionId == null) {
                          log.severe(
                              "[AppRouter] Edit Transaction route called without transaction ID!");
                          return const Scaffold(
                              body: Center(
                                  child:
                                      Text("Error: Missing Transaction ID")));
                        }
                        if (initialData == null) {
                          log.warning(
                              "[AppRouter] Edit Transaction route called without transaction data in 'extra'.");
                          // Optionally fetch transaction by ID here as a fallback
                        }
                        log.info(
                            "[AppRouter] Building edit_transaction: ID=$transactionId, Data provided=${initialData != null}");
                        // Pass dynamic data, page will handle conversion
                        return AddEditTransactionPage(
                            initialTransactionData: initialData);
                      }),
                  GoRoute(
                    // Keep detail route if separate
                    path:
                        '${RouteNames.transactionDetail}/:${RouteNames.paramTransactionId}',
                    name: RouteNames.transactionDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildTransactionDetailPage, // Keep helper
                  ),
                ],
              ),
            ],
          ),
          // --- Other Branches (Keep as is) ---
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
                    ],
                  ),
                  GoRoute(
                    path: RouteNames.createBudget,
                    name: RouteNames.createBudget,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const PlaceholderScreen(featureName: 'Create Budget'),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyAccounts,
            routes: [
              GoRoute(
                path: RouteNames.accounts, // Base path: /accounts
                name: RouteNames.accounts,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: AccountsTabPage()),
                routes: [
                  GoRoute(
                    path: RouteNames
                        .addAccount, // Relative path: add_account -> /accounts/add_account
                    name: RouteNames.addAccount,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditAccountPage(),
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.editAccount}/:${RouteNames.paramAccountId}', // Relative path: edit_account/:accountId -> /accounts/edit_account/:accountId
                    name: RouteNames.editAccount,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildEditAccountPage,
                  ),
                  GoRoute(
                    path: RouteNames
                        .addLiabilityAccount, // Relative path: add_liability_account -> /accounts/add_liability_account
                    name: RouteNames.addLiabilityAccount,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const PlaceholderScreen(
                        featureName: 'Add Liability Account'),
                  ),
                  GoRoute(
                      path:
                          '${RouteNames.accountDetail}/:${RouteNames.paramAccountId}', // Relative path: account_detail/:accountId -> /accounts/account_detail/:accountId
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
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeySettings,
            routes: [
              GoRoute(
                  path: RouteNames.settings,
                  name: RouteNames.settings,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: SettingsPage()),
                  routes: [
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
    // --- Keep errorBuilder ---
    errorBuilder: (context, state) {
      log.severe(
          "[AppRouter] Error - Path: '${state.uri}', Error: ${state.error}");
      return Scaffold(
        appBar: AppBar(title: const Text("Error")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Oops! Page not found or an error occurred.\n\nPath: ${state.uri}\nError: ${state.error}",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    },
  );

  // --- Keep Other Builder Helpers ---
  static Widget _buildTransactionDetailPage(
      BuildContext context, GoRouterState state) {
    // ... (implementation as before) ...
    log.info("[AppRouter] Attempting to build Transaction Detail page.");
    log.info("[AppRouter] Path params: ${state.pathParameters}");
    log.info("[AppRouter] Extra data type: ${state.extra?.runtimeType}");
    final id = state.pathParameters[RouteNames.paramTransactionId];
    TransactionEntity? transaction;
    if (state.extra is TransactionEntity) {
      transaction = state.extra as TransactionEntity;
    } else {
      log.warning(
          "[AppRouter] Transaction Detail route received 'extra' of unexpected type or null. Extra: ${state.extra?.runtimeType}");
    }

    if (id == null || transaction == null) {
      log.severe(
          "[AppRouter] Transaction Detail route missing ID or valid transaction data!");
      return Scaffold(
          appBar: AppBar(),
          body: const Center(
              child: Text("Error: Could not load transaction details")));
    }
    return TransactionDetailPage(transaction: transaction);
  }

  static Widget _buildEditCategoryPage(
      BuildContext context, GoRouterState state) {
    // ... (implementation as before) ...
    log.info("[AppRouter] Attempting to build Edit Category page.");
    log.info("[AppRouter] Path params: ${state.pathParameters}");
    log.info("[AppRouter] Extra data type: ${state.extra?.runtimeType}");
    final categoryId = state.pathParameters[RouteNames.paramId];
    final category = state.extra as Category?;
    log.info(
        "[AppRouter] Building edit_category: ID=$categoryId, Category provided=${category != null}");
    if (categoryId == null) {
      log.severe("[AppRouter] Edit Category route called without ID!");
      return const Scaffold(
          body: Center(child: Text("Error: Missing Category ID")));
    }
    if (category == null) {
      log.warning(
          "[AppRouter] Edit Category route called without valid Category data in 'extra'. Add mode assumed?");
    }
    return AddEditCategoryScreen(initialCategory: category);
  }

  static Widget _buildEditAccountPage(
      BuildContext context, GoRouterState state) {
    // ... (implementation as before) ...
    log.info("[AppRouter] Attempting to build Edit Account page.");
    log.info("[AppRouter] Path params: ${state.pathParameters}");
    log.info("[AppRouter] Extra data type: ${state.extra?.runtimeType}");
    final accountId = state.pathParameters[RouteNames.paramAccountId];
    final account = state.extra as AssetAccount?;
    log.info(
        "[AppRouter] Building edit_account: ID=$accountId, Account provided=${account != null}");
    if (accountId == null) {
      log.severe("[AppRouter] Edit Account route called without ID!");
      return const Scaffold(
          body: Center(child: Text("Error: Missing Account ID")));
    }
    if (account == null) {
      log.warning(
          "[AppRouter] Edit Account route called without valid AssetAccount data in 'extra'. Fetching might be needed.");
    }
    return AddEditAccountPage(accountId: accountId, account: account);
  }
}

// --- Keep GoRouterObserver and StringExtension ---
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String pushedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine('GoRouter Pushed: $pushedRoute <- ${previousRouteName ?? 'null'}');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String poppedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine('GoRouter Popped: $poppedRoute -> ${previousRouteName ?? 'null'}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String removedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    log.fine('GoRouter Removed: $removedRoute');
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final String oldRouteName = oldRoute?.settings.name ??
        oldRoute?.settings.arguments?.toString() ??
        'null';
    final String newRouteName = newRoute?.settings.name ??
        newRoute?.settings.arguments?.toString() ??
        'null';
    log.fine('GoRouter Replaced: $oldRouteName with $newRouteName');
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
