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
import 'package:expense_tracker/features/transactions/presentation/pages/add_edit_transaction_page.dart';
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
      observers: [
        GoRouterObserver()
      ], // Use the observer

      routes: [
        // =========================== //
        // === Main Application Shell === //
        // =========================== //
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
                  path: RouteNames.dashboard, // "/dashboard"
                  name: RouteNames.dashboard,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: DashboardPage()),
                  // Add dashboard sub-routes here if needed, opening in the root navigator
                  // routes: [
                  //   GoRoute(path: 'details', parentNavigatorKey: _rootNavigatorKey, ...),
                  // ]
                ),
              ],
            ),

            // --- Branch 1: Transactions ---
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyTransactions,
              routes: [
                GoRoute(
                  path: RouteNames.transactionsList, // "/transactions"
                  name: RouteNames.transactionsList,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: TransactionListPage()),
                  routes: [
                    // Add/Edit routes pushed onto the root navigator (full screen)
                    GoRoute(
                        path: RouteNames
                            .addTransaction, // "add" -> /transactions/add
                        name: RouteNames.addTransaction,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) {
                          log.info(
                              "[AppRouter] Building Add Transaction page.");
                          return const AddEditTransactionPage(
                              initialTransactionData: null);
                        }),
                    GoRoute(
                      path:
                          '${RouteNames.editTransaction}/:${RouteNames.paramTransactionId}', // "edit/:transactionId" -> /transactions/edit/:id
                      name: RouteNames.editTransaction,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _buildEditTransactionPage, // Use helper
                    ), // End of GoRoute for editTransaction
                    // Detail route (if needed separately from edit)
                    GoRoute(
                      path:
                          '${RouteNames.transactionDetail}/:${RouteNames.paramTransactionId}', // "transaction_detail/:transactionId"
                      name: RouteNames.transactionDetail,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _buildTransactionDetailPage, // Keep helper
                    ),
                  ],
                ),
              ],
            ),

            // --- Branch 2: Budgets & Categories ---
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyBudgetsCats,
              routes: [
                GoRoute(
                  path: RouteNames.budgetsAndCats, // "/budgets-cats"
                  name: RouteNames.budgetsAndCats,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: BudgetsAndCatsTabPage()),
                  routes: [
                    // Manage Categories route (within this shell branch)
                    GoRoute(
                      path: RouteNames
                          .manageCategories, // "manage_categories" -> /budgets-cats/manage_categories
                      name: RouteNames.manageCategories,
                      builder: (context, state) =>
                          const CategoryManagementScreen(),
                      routes: [
                        // Add/Edit Category routes pushed onto root navigator
                        GoRoute(
                          path: RouteNames
                              .addCategory, // "add_category" -> /budgets-cats/manage_categories/add_category
                          name: RouteNames.addCategory,
                          parentNavigatorKey: _rootNavigatorKey,
                          builder: (context, state) =>
                              const AddEditCategoryScreen(),
                        ),
                        GoRoute(
                          path:
                              '${RouteNames.editCategory}/:${RouteNames.paramId}', // "edit_category/:id"
                          name: RouteNames.editCategory,
                          parentNavigatorKey: _rootNavigatorKey,
                          builder: _buildEditCategoryPage, // Keep helper
                        ),
                      ],
                    ),
                    // Create Budget route pushed onto root navigator
                    GoRoute(
                      path: RouteNames
                          .createBudget, // "create_budget" -> /budgets-cats/create_budget
                      name: RouteNames.createBudget,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          const PlaceholderScreen(featureName: 'Create Budget'),
                    ),
                  ],
                ),
              ],
            ),

            // --- Branch 3: Accounts ---
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyAccounts,
              routes: [
                GoRoute(
                  path: RouteNames.accounts, // "/accounts"
                  name: RouteNames.accounts,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: AccountsTabPage()),
                  routes: [
                    // Add/Edit/Detail routes pushed onto root navigator
                    GoRoute(
                      path: RouteNames
                          .addAccount, // "add_account" -> /accounts/add_account
                      name: RouteNames.addAccount,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const AddEditAccountPage(),
                    ),
                    GoRoute(
                      path:
                          '${RouteNames.editAccount}/:${RouteNames.paramAccountId}', // "edit_account/:accountId"
                      name: RouteNames.editAccount,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _buildEditAccountPage, // Keep helper
                    ),
                    GoRoute(
                      path: RouteNames
                          .addLiabilityAccount, // "add_liability_account"
                      name: RouteNames.addLiabilityAccount,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const PlaceholderScreen(
                          featureName: 'Add Liability Account'),
                    ),
                    GoRoute(
                        path:
                            '${RouteNames.accountDetail}/:${RouteNames.paramAccountId}', // "account_detail/:accountId"
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
                    path: RouteNames.settings, // "/settings"
                    name: RouteNames.settings,
                    pageBuilder: (context, state) =>
                        const NoTransitionPage(child: SettingsPage()),
                    routes: [
                      // Sub-settings routes pushed onto root navigator
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
                          builder: (c, s) => const PlaceholderScreen(
                              featureName: 'Trash Bin')),
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
                          builder: (c, s) => const PlaceholderScreen(
                              featureName: 'About App')),
                    ]),
              ],
            ),
          ],
        ),
      ]);

  // --- Helper Builder Functions (Keep as is) ---
  static Widget _buildTransactionDetailPage(
      BuildContext context, GoRouterState state) {
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

  static Widget _buildEditTransactionPage(
      BuildContext context, GoRouterState state) {
    log.info("[AppRouter] Attempting to build Edit Transaction page.");
    final transactionId = state.pathParameters[RouteNames.paramTransactionId];
    TransactionEntity? initialData; // Explicitly typed

    if (state.extra is TransactionEntity) {
      initialData = state.extra as TransactionEntity;
    } else if (state.extra != null) {
      log.warning(
          "[AppRouter] Edit Transaction route received 'extra' of unexpected type: ${state.extra?.runtimeType}. Ignoring extra data.");
    }

    if (transactionId == null) {
      log.severe(
          "[AppRouter] Edit Transaction route called without transaction ID!");
      return const Scaffold(
          appBar: null, // Consistent with other error scaffolds
          body: Center(child: Text("Error: Missing Transaction ID")));
    }

    log.info(
        "[AppRouter] Building edit_transaction: ID=$transactionId, Data provided=${initialData != null}");
    // AddEditTransactionPage should handle fetching if initialData is null
    return AddEditTransactionPage(initialTransactionData: initialData);
  }

  static Widget _buildEditCategoryPage(
      BuildContext context, GoRouterState state) {
    final categoryId = state.pathParameters[RouteNames.paramId];
    final category = state.extra as Category?;
    if (categoryId == null) {
      log.severe("[AppRouter] Edit Category route called without ID!");
      return const Scaffold(
          appBar: null, // Consistent with other error scaffolds
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
    final accountId = state.pathParameters[RouteNames.paramAccountId];
    final account = state.extra as AssetAccount?;
    if (accountId == null) {
      log.severe("[AppRouter] Edit Account route called without ID!");
      return const Scaffold(
          appBar: null, // Consistent with other error scaffolds
          body: Center(child: Text("Error: Missing Account ID")));
    }
    if (account == null) {
      log.warning(
          "[AppRouter] Edit Account route called without valid AssetAccount data in 'extra'. Fetching might be needed.");
    }
    return AddEditAccountPage(accountId: accountId, account: account);
  }
}

// --- GoRouterObserver (Keep as is or enhance logging) ---
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String pushedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine(
        'GoRouter Pushed: ${previousRouteName ?? 'null'} -> $pushedRoute'); // Improved order
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String poppedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine(
        'GoRouter Popped: $poppedRoute -> Returning to ${previousRouteName ?? 'null'}'); // Improved wording
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String removedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine(
        'GoRouter Removed: $removedRoute (Previous was: ${previousRouteName ?? 'null'})'); // Added context
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

// Keep StringExtension
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
