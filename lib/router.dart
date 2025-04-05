// lib/router.dart
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
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
// --- Import Budget/Goal Pages ---
import 'package:expense_tracker/features/budgets/presentation/pages/add_edit_budget_page.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:expense_tracker/features/goals/presentation/pages/add_edit_goal_page.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goal_detail_page.dart';

// Import Placeholder Screen (should not be used by budget/goal routes now)
import 'package:expense_tracker/core/widgets/placeholder_screen.dart';

// Import Shell Widget
import 'main_shell.dart';

// Import Route Names constants
import 'package:expense_tracker/core/constants/route_names.dart';

// Import Entities for 'extra' parameter type safety
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
// --- Import Budget/Goal Entities ---
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';

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
                    ),
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

            // --- Branch 2: Budgets & Categories & Goals ---
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyBudgetsCats,
              routes: [
                GoRoute(
                  path: RouteNames.budgetsAndCats, // "/budgets-cats"
                  name: RouteNames.budgetsAndCats,
                  pageBuilder: (context, state) =>
                      const NoTransitionPage(child: BudgetsAndCatsTabPage()),
                  routes: [
                    // -- Category Routes --
                    GoRoute(
                      path: RouteNames.manageCategories, // "manage_categories"
                      name: RouteNames.manageCategories,
                      builder: (context, state) =>
                          const CategoryManagementScreen(),
                      routes: [
                        GoRoute(
                          path: RouteNames.addCategory, // "add_category"
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
                    // -- Budget Routes --
                    GoRoute(
                      path: RouteNames
                          .addBudget, // "add_budget" (replaces createBudget)
                      name: RouteNames.addBudget,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const AddEditBudgetPage(
                          initialBudget: null), // Always adding here
                    ),
                    GoRoute(
                      path:
                          '${RouteNames.editBudget}/:${RouteNames.paramId}', // "edit_budget/:id"
                      name: RouteNames.editBudget,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _buildEditBudgetPage, // Use helper
                    ),
                    GoRoute(
                      path:
                          '${RouteNames.budgetDetail}/:${RouteNames.paramId}', // "budget_detail/:id"
                      name: RouteNames.budgetDetail,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _buildBudgetDetailPage, // Use helper
                    ),
                    // -- Goal Routes --
                    GoRoute(
                      path: RouteNames.addGoal, // "add_goal"
                      name: RouteNames.addGoal,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) => const AddEditGoalPage(
                          initialGoal: null), // Always adding here
                    ),
                    GoRoute(
                      path:
                          '${RouteNames.editGoal}/:${RouteNames.paramId}', // "edit_goal/:id"
                      name: RouteNames.editGoal,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _buildEditGoalPage, // Use helper
                    ),
                    GoRoute(
                      path:
                          '${RouteNames.goalDetail}/:${RouteNames.paramId}', // "goal_detail/:id"
                      name: RouteNames.goalDetail,
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: _buildGoalDetailPage, // Use helper
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
                    GoRoute(
                      path: RouteNames.addAccount, // "add_account"
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
                          // TODO: Replace with actual Account Detail Page
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

  // --- Helper Builder Functions (Transactions, Categories, Accounts - Keep as is) ---
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
    dynamic initialData = state.extra; // Keep dynamic initially

    // Check if initialData is Expense or Income
    if (initialData != null &&
        !(initialData is Expense || initialData is Income)) {
      log.warning(
          "[AppRouter] Edit Transaction route received 'extra' of unexpected type: ${state.extra?.runtimeType}. Ignoring extra data.");
      initialData = null; // Reset if wrong type
    }

    if (transactionId == null) {
      log.severe(
          "[AppRouter] Edit Transaction route called without transaction ID!");
      return const Scaffold(
          appBar: null,
          body: Center(child: Text("Error: Missing Transaction ID")));
    }

    log.info(
        "[AppRouter] Building edit_transaction: ID=$transactionId, Data provided=${initialData != null}");
    // Pass the initial data (which is Expense or Income)
    return AddEditTransactionPage(initialTransactionData: initialData);
  }

  static Widget _buildEditCategoryPage(
      BuildContext context, GoRouterState state) {
    final categoryId = state.pathParameters[RouteNames.paramId];
    final category = state.extra as Category?;
    if (categoryId == null) {
      log.severe("[AppRouter] Edit Category route called without ID!");
      return const Scaffold(
          appBar: null,
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
          appBar: null, body: Center(child: Text("Error: Missing Account ID")));
    }
    if (account == null) {
      log.warning(
          "[AppRouter] Edit Account route called without valid AssetAccount data in 'extra'. Fetching might be needed.");
    }
    return AddEditAccountPage(accountId: accountId, account: account);
  }

  // --- NEW Helper Builder Functions (Budgets, Goals) ---
  static Widget _buildEditBudgetPage(
      BuildContext context, GoRouterState state) {
    final budgetId = state.pathParameters[RouteNames.paramId];
    final budget = state.extra as Budget?;
    if (budgetId == null) {
      log.severe("[AppRouter] Edit Budget route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Budget ID")));
    }
    if (budget == null) {
      log.warning(
          "[AppRouter] Edit Budget route called without valid Budget data in 'extra'.");
    }
    return AddEditBudgetPage(initialBudget: budget);
  }

  static Widget _buildBudgetDetailPage(
      BuildContext context, GoRouterState state) {
    final budgetId = state.pathParameters[RouteNames.paramId];
    if (budgetId == null) {
      log.severe("[AppRouter] Budget Detail route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Budget ID")));
    }
    // BudgetDetailPage will fetch its own data using the ID
    return BudgetDetailPage(budgetId: budgetId);
  }

  static Widget _buildEditGoalPage(BuildContext context, GoRouterState state) {
    final goalId = state.pathParameters[RouteNames.paramId];
    final goal = state.extra as Goal?;
    if (goalId == null) {
      log.severe("[AppRouter] Edit Goal route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Goal ID")));
    }
    if (goal == null) {
      log.warning(
          "[AppRouter] Edit Goal route called without valid Goal data in 'extra'.");
    }
    return AddEditGoalPage(initialGoal: goal);
  }

  static Widget _buildGoalDetailPage(
      BuildContext context, GoRouterState state) {
    final goalId = state.pathParameters[RouteNames.paramId];
    final goal =
        state.extra as Goal?; // Pass goal if available for faster initial load
    if (goalId == null) {
      log.severe("[AppRouter] Goal Detail route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Goal ID")));
    }
    return GoalDetailPage(goalId: goalId, initialGoal: goal);
  }
}

// --- GoRouterObserver (Keep as is) ---
class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String pushedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine('GoRouter Pushed: ${previousRouteName ?? 'null'} -> $pushedRoute');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String poppedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine(
        'GoRouter Popped: $poppedRoute -> Returning to ${previousRouteName ?? 'null'}');
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String removedRoute = route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName = previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine(
        'GoRouter Removed: $removedRoute (Previous was: ${previousRouteName ?? 'null'})');
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
