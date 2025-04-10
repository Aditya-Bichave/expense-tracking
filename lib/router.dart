// lib/router.dart
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart'; // Import BlocProvider
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
import 'package:expense_tracker/features/budgets/presentation/pages/add_edit_budget_page.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:expense_tracker/features/goals/presentation/pages/add_edit_goal_page.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goal_detail_page.dart';
// --- Import Report Pages ---
import 'package:expense_tracker/features/reports/presentation/pages/spending_by_category_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/spending_over_time_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/income_vs_expense_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/budget_performance_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/goal_progress_page.dart';
// --- Import Report Blocs ---
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';

import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'main_shell.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';

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
      ],
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) {
            // --- Provide ReportFilterBloc here for all shell branches ---
            return BlocProvider.value(
              value: sl<ReportFilterBloc>(), // Use the singleton instance
              child: MainShell(navigationShell: navigationShell),
            );
            // --- End Provide ---
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
                  routes: _buildReportSubRoutes(
                      _rootNavigatorKey), // Keep reports nested here
                ),
              ],
            ),
            // --- Other Branches (Unchanged) ---
            StatefulShellBranch(
              navigatorKey: _shellNavigatorKeyTransactions,
              routes: [
                GoRoute(
                  path: RouteNames.transactionsList,
                  name: RouteNames.transactionsList,
                  pageBuilder: (context, state) {
                    final Map<String, dynamic> queryParams =
                        state.uri.queryParameters;
                    final Map<String, dynamic>? extra =
                        state.extra as Map<String, dynamic>?;
                    Map<String, dynamic>? filtersFromExtra =
                        extra?['filters'] as Map<String, dynamic>?;
                    log.fine(
                        "[Router] TransactionsListPage: queryParams=$queryParams, extra=$extra, filtersFromExtra=$filtersFromExtra");
                    return NoTransitionPage(
                        child: TransactionListPage(
                      initialFilters: filtersFromExtra ?? queryParams,
                    ));
                  },
                  routes: [
                    GoRoute(
                        path: RouteNames.addTransaction,
                        name: RouteNames.addTransaction,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const AddEditTransactionPage(
                                initialTransactionData: null)),
                    GoRoute(
                        path:
                            '${RouteNames.editTransaction}/:${RouteNames.paramTransactionId}',
                        name: RouteNames.editTransaction,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: _buildEditTransactionPage),
                    GoRoute(
                        path:
                            '${RouteNames.transactionDetail}/:${RouteNames.paramTransactionId}',
                        name: RouteNames.transactionDetail,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: _buildTransactionDetailPage),
                  ],
                ),
              ],
            ),
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
                      parentNavigatorKey: _rootNavigatorKey,
                      builder: (context, state) =>
                          const CategoryManagementScreen(),
                      routes: [
                        GoRoute(
                            path: RouteNames.addCategory,
                            name: RouteNames.addCategory,
                            parentNavigatorKey: _rootNavigatorKey,
                            builder: (context, state) => AddEditCategoryScreen(
                                initialType:
                                    (state.extra as Map<String, dynamic>?)?[
                                        'initialType'] as CategoryType?)),
                        GoRoute(
                            path:
                                '${RouteNames.editCategory}/:${RouteNames.paramId}',
                            name: RouteNames.editCategory,
                            parentNavigatorKey: _rootNavigatorKey,
                            builder: _buildEditCategoryPage),
                      ],
                    ),
                    GoRoute(
                        path: RouteNames.addBudget,
                        name: RouteNames.addBudget,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const AddEditBudgetPage(initialBudget: null)),
                    GoRoute(
                        path: '${RouteNames.editBudget}/:${RouteNames.paramId}',
                        name: RouteNames.editBudget,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: _buildEditBudgetPage),
                    GoRoute(
                        path:
                            '${RouteNames.budgetDetail}/:${RouteNames.paramId}',
                        name: RouteNames.budgetDetail,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: _buildBudgetDetailPage),
                    GoRoute(
                        path: RouteNames.addGoal,
                        name: RouteNames.addGoal,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) =>
                            const AddEditGoalPage(initialGoal: null)),
                    GoRoute(
                        path: '${RouteNames.editGoal}/:${RouteNames.paramId}',
                        name: RouteNames.editGoal,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: _buildEditGoalPage),
                    GoRoute(
                        path: '${RouteNames.goalDetail}/:${RouteNames.paramId}',
                        name: RouteNames.goalDetail,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: _buildGoalDetailPage),
                  ],
                ),
              ],
            ),
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
                        builder: (context, state) =>
                            const AddEditAccountPage()),
                    GoRoute(
                        path:
                            '${RouteNames.editAccount}/:${RouteNames.paramAccountId}',
                        name: RouteNames.editAccount,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: _buildEditAccountPage),
                    GoRoute(
                        path: RouteNames.addLiabilityAccount,
                        name: RouteNames.addLiabilityAccount,
                        parentNavigatorKey: _rootNavigatorKey,
                        builder: (context, state) => const PlaceholderScreen(
                            featureName: 'Add Liability Account')),
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

  // --- Report Sub-Routes Builder (Provide Blocs here) ---
  static List<RouteBase> _buildReportSubRoutes(
      GlobalKey<NavigatorState> parentKey) {
    return [
      GoRoute(
        path: RouteNames.reportSpendingCategory,
        name: RouteNames.reportSpendingCategory,
        parentNavigatorKey: parentKey,
        // --- FIXED: Provide Bloc ---
        pageBuilder: (context, state) => MaterialPage(
          // Use MaterialPage for transitions
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => sl<SpendingCategoryReportBloc>(),
            // Provide the singleton ReportFilterBloc to the page
            child: BlocProvider.value(
              value: sl<ReportFilterBloc>(),
              child: const SpendingByCategoryPage(),
            ),
          ),
        ),
        // --- END FIX ---
      ),
      GoRoute(
        path: RouteNames.reportSpendingTime,
        name: RouteNames.reportSpendingTime,
        parentNavigatorKey: parentKey,
        // --- FIXED: Provide Bloc ---
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => sl<SpendingTimeReportBloc>(),
            child: BlocProvider.value(
              value: sl<ReportFilterBloc>(),
              child: const SpendingOverTimePage(),
            ),
          ),
        ),
        // --- END FIX ---
      ),
      GoRoute(
        path: RouteNames.reportIncomeExpense,
        name: RouteNames.reportIncomeExpense,
        parentNavigatorKey: parentKey,
        // --- FIXED: Provide Bloc ---
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => sl<IncomeExpenseReportBloc>(),
            child: BlocProvider.value(
              value: sl<ReportFilterBloc>(),
              child: const IncomeVsExpensePage(),
            ),
          ),
        ),
        // --- END FIX ---
      ),
      GoRoute(
        path: RouteNames.reportBudgetPerformance, // Added
        name: RouteNames.reportBudgetPerformance,
        parentNavigatorKey: parentKey,
        // --- FIXED: Provide Bloc ---
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => sl<BudgetPerformanceReportBloc>(),
            child: BlocProvider.value(
              value: sl<ReportFilterBloc>(),
              child: const BudgetPerformancePage(),
            ),
          ),
        ),
        // --- END FIX ---
      ),
      GoRoute(
        path: RouteNames.reportGoalProgress, // Added
        name: RouteNames.reportGoalProgress,
        parentNavigatorKey: parentKey,
        // --- FIXED: Provide Bloc ---
        pageBuilder: (context, state) => MaterialPage(
          key: state.pageKey,
          child: BlocProvider(
            create: (_) => sl<GoalProgressReportBloc>(),
            child: BlocProvider.value(
              value: sl<ReportFilterBloc>(),
              child: const GoalProgressPage(),
            ),
          ),
        ),
        // --- END FIX ---
      ),
    ];
  }

  // --- Helper Builder Functions (Unchanged) ---
  static Widget _buildTransactionDetailPage(
      BuildContext context, GoRouterState state) {
    /* ... */
    final id = state.pathParameters[RouteNames.paramTransactionId];
    TransactionEntity? transaction;
    if (state.extra is TransactionEntity) {
      transaction = state.extra as TransactionEntity;
    } else {
      log.warning(
          "[AppRouter] Txn Detail route received 'extra' of unexpected type or null. Extra: ${state.extra?.runtimeType}");
    }
    if (id == null || transaction == null) {
      log.severe(
          "[AppRouter] Txn Detail route missing ID or valid transaction data!");
      return Scaffold(
          appBar: AppBar(),
          body: const Center(
              child: Text("Error: Could not load transaction details")));
    }
    return TransactionDetailPage(transaction: transaction);
  }

  static Widget _buildEditTransactionPage(
      BuildContext context, GoRouterState state) {
    /* ... */
    final transactionId = state.pathParameters[RouteNames.paramTransactionId];
    dynamic initialData = state.extra;
    if (initialData != null &&
        !(initialData is Expense ||
            initialData is Income ||
            initialData is TransactionEntity)) {
      log.warning(
          "[AppRouter] Edit Txn route received 'extra' of unexpected type: ${state.extra?.runtimeType}. Ignoring.");
      initialData = null;
    }
    if (transactionId == null) {
      log.severe("[AppRouter] Edit Txn route called without transaction ID!");
      return const Scaffold(
          appBar: null,
          body: Center(child: Text("Error: Missing Transaction ID")));
    }
    return AddEditTransactionPage(initialTransactionData: initialData);
  }

  static Widget _buildEditCategoryPage(
      BuildContext context, GoRouterState state) {
    /* ... */
    final categoryId = state.pathParameters[RouteNames.paramId];
    final category = state.extra as Category?;
    final initialType =
        (state.extra as Map<String, dynamic>?)?['initialType'] as CategoryType?;
    if (categoryId == null) {
      log.severe("[AppRouter] Edit Category route called without ID!");
      return const Scaffold(
          appBar: null,
          body: Center(child: Text("Error: Missing Category ID")));
    }
    return AddEditCategoryScreen(
        initialCategory: category, initialType: initialType);
  }

  static Widget _buildEditAccountPage(
      BuildContext context, GoRouterState state) {
    /* ... */
    final accountId = state.pathParameters[RouteNames.paramAccountId];
    final account = state.extra as AssetAccount?;
    if (accountId == null) {
      log.severe("[AppRouter] Edit Account route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Account ID")));
    }
    return AddEditAccountPage(accountId: accountId, account: account);
  }

  static Widget _buildEditBudgetPage(
      BuildContext context, GoRouterState state) {
    /* ... */
    final budgetId = state.pathParameters[RouteNames.paramId];
    final budget = state.extra as Budget?;
    if (budgetId == null) {
      log.severe("[AppRouter] Edit Budget route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Budget ID")));
    }
    return AddEditBudgetPage(initialBudget: budget);
  }

  static Widget _buildBudgetDetailPage(
      BuildContext context, GoRouterState state) {
    /* ... */
    final budgetId = state.pathParameters[RouteNames.paramId];
    if (budgetId == null) {
      log.severe("[AppRouter] Budget Detail route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Budget ID")));
    }
    return BudgetDetailPage(budgetId: budgetId);
  }

  static Widget _buildEditGoalPage(BuildContext context, GoRouterState state) {
    /* ... */
    final goalId = state.pathParameters[RouteNames.paramId];
    final goal = state.extra as Goal?;
    if (goalId == null) {
      log.severe("[AppRouter] Edit Goal route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Goal ID")));
    }
    return AddEditGoalPage(initialGoal: goal);
  }

  static Widget _buildGoalDetailPage(
      BuildContext context, GoRouterState state) {
    /* ... */
    final goalId = state.pathParameters[RouteNames.paramId];
    final goal = state.extra as Goal?;
    if (goalId == null) {
      log.severe("[AppRouter] Goal Detail route called without ID!");
      return const Scaffold(
          appBar: null, body: Center(child: Text("Error: Missing Goal ID")));
    }
    return GoalDetailPage(goalId: goalId, initialGoal: goal);
  }
}

// --- GoRouterObserver ---
class GoRouterObserver extends NavigatorObserver {
  /* ... Unchanged ... */
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
  /* ... Unchanged ... */
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
