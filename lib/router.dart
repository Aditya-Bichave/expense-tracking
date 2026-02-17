// lib/router.dart
import 'dart:async';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl
import 'package:expense_tracker/core/screens/initial_setup_screen.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/add_edit_account_page.dart';
import 'package:expense_tracker/features/accounts/presentation/pages/accounts_tab_page.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/add_edit_budget_page.dart';
import 'package:expense_tracker/features/budgets/presentation/pages/budget_detail_page.dart';
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/presentation/pages/add_edit_category_screen.dart';
import 'package:expense_tracker/features/categories/presentation/pages/category_management_screen.dart';
import 'package:expense_tracker/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/presentation/pages/add_edit_goal_page.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/pages/add_edit_recurring_rule_page.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/pages/recurring_rule_list_page.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/pages/budget_performance_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/goal_progress_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/income_vs_expense_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/spending_by_category_page.dart';
import 'package:expense_tracker/features/reports/presentation/pages/spending_over_time_page.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsBloc
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/add_edit_transaction_page.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/main_shell.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Simple Listenable that refreshes GoRouter when the stream emits
class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

// --- Navigator Keys ---
final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _shellNavigatorKeyDashboard =
    GlobalKey<NavigatorState>(debugLabel: 'shellDashboard');
final GlobalKey<NavigatorState> _shellNavigatorKeyTransactions =
    GlobalKey<NavigatorState>(debugLabel: 'shellTransactions');
final GlobalKey<NavigatorState> _shellNavigatorKeyBudgetsCats =
    GlobalKey<NavigatorState>(debugLabel: 'shellBudgetsCats');
final GlobalKey<NavigatorState> _shellNavigatorKeyAccounts =
    GlobalKey<NavigatorState>(debugLabel: 'shellAccounts');
final GlobalKey<NavigatorState> _shellNavigatorKeyRecurring =
    GlobalKey<NavigatorState>(debugLabel: 'shellRecurring');
final GlobalKey<NavigatorState> _shellNavigatorKeySettings =
    GlobalKey<NavigatorState>(debugLabel: 'shellSettings');

// --- Router Configuration ---
class AppRouter {
  static final SettingsBloc _settingsBloc = sl<SettingsBloc>();

  static final GoRouter router = GoRouter(
    // --- FIXED: Set initialLocation to /setup ---
    initialLocation: RouteNames.initialSetup,
    // --- END FIXED ---
    navigatorKey: _rootNavigatorKey,
    debugLogDiagnostics: kDebugMode,
    observers: [GoRouterObserver()],
    refreshListenable: GoRouterRefreshStream(_settingsBloc.stream),
    redirect: (BuildContext context, GoRouterState state) {
      final settingsState = _settingsBloc.state;
      final bool isInDemo = settingsState.isInDemoMode;
      final bool isInitialized =
          settingsState.status == SettingsStatus.loaded ||
          settingsState.status == SettingsStatus.error;
      final bool setupSkipped = settingsState.setupSkipped;

      const bool isAuthenticated = false; // MOCK

      final String currentRoute = state.matchedLocation;
      final bool isGoingToInitialSetup =
          currentRoute == RouteNames.initialSetup;
      final bool isGoingToShellRoute =
          currentRoute == RouteNames.dashboard ||
          currentRoute == RouteNames.transactionsList ||
          currentRoute == RouteNames.budgetsAndCats ||
          currentRoute == RouteNames.accounts ||
          currentRoute == RouteNames.settings ||
          currentRoute.startsWith(RouteNames.recurring);

      log.info(
        "[RouterRedirect] To: $currentRoute, IsInDemo: $isInDemo, IsAuth: $isAuthenticated, IsInit: $isInitialized, SetupSkipped: $setupSkipped",
      );

      if (setupSkipped && isGoingToInitialSetup) {
        log.info(
          "[RouterRedirect] Setup skipped, redirecting from InitialSetup to Dashboard.",
        );
        return RouteNames.dashboard;
      }

      // Don't redirect if settings aren't initialized unless going to setup
      if (!isInitialized && !isGoingToInitialSetup) {
        log.info(
          "[RouterRedirect] Settings not initialized, staying put (or default).",
        );
        return null;
      }

      // If in demo mode, allow access to shell routes, redirect away from setup
      if (isInDemo) {
        if (isGoingToInitialSetup) {
          log.info(
            "[RouterRedirect] In Demo Mode, redirecting from InitialSetup to Dashboard.",
          );
          return RouteNames.dashboard;
        }
        log.info(
          "[RouterRedirect] In Demo Mode, allowing access to $currentRoute.",
        );
        return null; // No redirection needed
      }

      // If NOT authenticated AND NOT in demo mode
      if (!isAuthenticated && !isInDemo) {
        // If already on the setup page, allow it
        if (isGoingToInitialSetup) {
          log.info(
            "[RouterRedirect] Not authenticated, already on InitialSetup. Allowing.",
          );
          return null;
        }
        // If setup was skipped AND trying to access a shell route, allow it
        else if (setupSkipped && isGoingToShellRoute) {
          log.info(
            "[RouterRedirect] Not authenticated, but setup was skipped. Allowing navigation to $currentRoute.",
          );
          return null; // Allow navigation
        }
        // Otherwise, redirect to InitialSetup
        else {
          log.info(
            "[RouterRedirect] Not authenticated & setup not skipped/not going to setup, redirecting to InitialSetup.",
          );
          return RouteNames.initialSetup;
        }
      }

      // Default: Allow navigation to the intended route (if reached here, conditions are met)
      log.info("[RouterRedirect] Allowing access to $currentRoute.");
      return null;
    },
    routes: [
      // Initial Setup Route - This is the route for the initial screen
      GoRoute(
        path: RouteNames.initialSetup,
        name: RouteNames.initialSetup,
        builder: (context, state) => const InitialSetupScreen(),
      ),

      // Main App Shell Routes - These are the main screens accessible after setup/login
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return BlocProvider.value(
            value: sl<ReportFilterBloc>(),
            child: MainShell(navigationShell: navigationShell),
          );
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
                routes: _buildReportSubRoutes(_rootNavigatorKey),
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
                pageBuilder: (context, state) {
                  final Map<String, dynamic> queryParams =
                      state.uri.queryParameters;
                  final Map<String, dynamic>? extra =
                      state.extra as Map<String, dynamic>?;
                  Map<String, dynamic>? filtersFromExtra =
                      extra?['filters'] as Map<String, dynamic>?;
                  log.fine(
                    "[Router] TransactionsListPage: queryParams=$queryParams, extra=$extra, filtersFromExtra=$filtersFromExtra",
                  );
                  return NoTransitionPage(
                    child: TransactionListPage(
                      initialFilters: filtersFromExtra ?? queryParams,
                    ),
                  );
                },
                routes: [
                  GoRoute(
                    path: RouteNames.addTransaction,
                    name: RouteNames.addTransaction,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final merchantId =
                          state.uri.queryParameters['merchantId'];
                      // Safely handle extra, which might be a String or a Map or null
                      String? merchantIdFromExtra;
                      if (state.extra is String) {
                        merchantIdFromExtra = state.extra as String;
                      } else if (state.extra is Map<String, dynamic>) {
                        final extraMap = state.extra as Map<String, dynamic>;
                        merchantIdFromExtra = extraMap['merchantId'] as String?;
                      }

                      return AddEditTransactionPage(
                        initialTransactionData: null,
                        merchantId: merchantId ?? merchantIdFromExtra,
                      );
                    },
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.editTransaction}/:${RouteNames.paramTransactionId}',
                    name: RouteNames.editTransaction,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildEditTransactionPage,
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
          // --- Branch 2: Budgets/Goals ---
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
                        builder: (context, state) {
                          final Map<String, dynamic>? extra =
                              state.extra as Map<String, dynamic>?;
                          final CategoryType? initialType =
                              extra?['initialType'] as CategoryType?;
                          return AddEditCategoryScreen(
                            initialType: initialType,
                          );
                        },
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
                    path: RouteNames.addBudget,
                    name: RouteNames.addBudget,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const AddEditBudgetPage(initialBudget: null),
                  ),
                  GoRoute(
                    path: '${RouteNames.editBudget}/:${RouteNames.paramId}',
                    name: RouteNames.editBudget,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildEditBudgetPage,
                  ),
                  GoRoute(
                    path: '${RouteNames.budgetDetail}/:${RouteNames.paramId}',
                    name: RouteNames.budgetDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildBudgetDetailPage,
                  ),
                  GoRoute(
                    path: RouteNames.addGoal,
                    name: RouteNames.addGoal,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const AddEditGoalPage(initialGoal: null),
                  ),
                  GoRoute(
                    path: '${RouteNames.editGoal}/:${RouteNames.paramId}',
                    name: RouteNames.editGoal,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildEditGoalPage,
                  ),
                  GoRoute(
                    path: '${RouteNames.goalDetail}/:${RouteNames.paramId}',
                    name: RouteNames.goalDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: _buildGoalDetailPage,
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
                ],
              ),
            ],
          ),
          // --- Branch 4: Recurring ---
          StatefulShellBranch(
            navigatorKey: _shellNavigatorKeyRecurring,
            routes: [
              GoRoute(
                path: RouteNames.recurring,
                name: RouteNames.recurring,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: RecurringRuleListPage()),
                routes: [
                  GoRoute(
                    path: RouteNames.addRecurring,
                    name: RouteNames.addRecurring,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        const AddEditRecurringRulePage(),
                  ),
                  GoRoute(
                    path: '${RouteNames.editRecurring}/:${RouteNames.paramId}',
                    name: RouteNames.editRecurring,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) {
                      final rule = state.extra as RecurringRule?;
                      return AddEditRecurringRulePage(initialRule: rule);
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
                path: RouteNames.settings,
                name: RouteNames.settings,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: SettingsPage()),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // --- Report Sub-Routes Builder (Unchanged) ---
  static List<RouteBase> _buildReportSubRoutes(
    GlobalKey<NavigatorState> parentKey,
  ) {
    return [
      GoRoute(
        path: RouteNames.reportSpendingCategory, // Relative path
        name: RouteNames.reportSpendingCategory,
        parentNavigatorKey: parentKey, // Ensure it pushes onto root
        pageBuilder: (context, state) {
          final filterBloc = sl<ReportFilterBloc>();
          return MaterialPage(
            key: state.pageKey,
            child: BlocProvider<ReportFilterBloc>(
              create: (_) => filterBloc,
              child: BlocProvider<SpendingCategoryReportBloc>(
                create: (_) =>
                    sl<SpendingCategoryReportBloc>(param1: filterBloc),
                child: const SpendingByCategoryPage(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.reportSpendingTime,
        name: RouteNames.reportSpendingTime,
        parentNavigatorKey: parentKey,
        pageBuilder: (context, state) {
          final filterBloc = sl<ReportFilterBloc>();
          return MaterialPage(
            key: state.pageKey,
            child: BlocProvider<ReportFilterBloc>(
              create: (_) => filterBloc,
              child: BlocProvider<SpendingTimeReportBloc>(
                create: (_) => sl<SpendingTimeReportBloc>(param1: filterBloc),
                child: const SpendingOverTimePage(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.reportIncomeExpense,
        name: RouteNames.reportIncomeExpense,
        parentNavigatorKey: parentKey,
        pageBuilder: (context, state) {
          final filterBloc = sl<ReportFilterBloc>();
          return MaterialPage(
            key: state.pageKey,
            child: BlocProvider<ReportFilterBloc>(
              create: (_) => filterBloc,
              child: BlocProvider<IncomeExpenseReportBloc>(
                create: (_) => sl<IncomeExpenseReportBloc>(param1: filterBloc),
                child: const IncomeVsExpensePage(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.reportBudgetPerformance,
        name: RouteNames.reportBudgetPerformance,
        parentNavigatorKey: parentKey,
        pageBuilder: (context, state) {
          final filterBloc = sl<ReportFilterBloc>();
          return MaterialPage(
            key: state.pageKey,
            child: BlocProvider<ReportFilterBloc>(
              create: (_) => filterBloc,
              child: BlocProvider<BudgetPerformanceReportBloc>(
                create: (_) =>
                    sl<BudgetPerformanceReportBloc>(param1: filterBloc),
                child: const BudgetPerformancePage(),
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: RouteNames.reportGoalProgress,
        name: RouteNames.reportGoalProgress,
        parentNavigatorKey: parentKey,
        pageBuilder: (context, state) {
          final filterBloc = sl<ReportFilterBloc>();
          return MaterialPage(
            key: state.pageKey,
            child: BlocProvider<ReportFilterBloc>(
              create: (_) => filterBloc,
              child: BlocProvider<GoalProgressReportBloc>(
                create: (_) => sl<GoalProgressReportBloc>(param1: filterBloc),
                child: const GoalProgressPage(),
              ),
            ),
          );
        },
      ),
    ];
  }

  // --- Helper Builder Functions (Unchanged) ---
  static Widget _buildTransactionDetailPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final id = state.pathParameters[RouteNames.paramTransactionId];
    TransactionEntity? transaction;
    if (state.extra is TransactionEntity) {
      transaction = state.extra as TransactionEntity;
    } else {
      log.warning(
        "[AppRouter] Txn Detail route received 'extra' of unexpected type or null. Extra: ${state.extra?.runtimeType}",
      );
    }
    if (id == null || transaction == null) {
      log.severe(
        "[AppRouter] Txn Detail route missing ID or valid transaction data!",
      );
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text("Error: Could not load transaction details"),
        ),
      );
    }
    return TransactionDetailPage(transaction: transaction);
  }

  static Widget _buildEditTransactionPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final transactionId = state.pathParameters[RouteNames.paramTransactionId];
    dynamic initialData = state.extra;
    if (initialData != null &&
        !(initialData is Expense ||
            initialData is Income ||
            initialData is TransactionEntity)) {
      log.warning(
        "[AppRouter] Edit Txn route received 'extra' of unexpected type: ${state.extra?.runtimeType}. Ignoring.",
      );
      initialData = null;
    }
    if (transactionId == null && initialData == null) {
      log.severe(
        "[AppRouter] Edit Txn route called without transaction ID or initial data!",
      );
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Transaction Data")),
      );
    }
    return AddEditTransactionPage(initialTransactionData: initialData);
  }

  static Widget _buildEditCategoryPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final categoryId = state.pathParameters[RouteNames.paramId];
    final Category? category = state.extra is Category
        ? state.extra as Category
        : null;
    final Map<String, dynamic>? extraMap = state.extra is Map<String, dynamic>
        ? state.extra as Map<String, dynamic>
        : null;
    final CategoryType? initialType = extraMap?['initialType'] as CategoryType?;

    if (categoryId == null) {
      log.severe("[AppRouter] Edit Category route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Category ID")),
      );
    }
    return AddEditCategoryScreen(
      initialCategory: category,
      initialType: initialType,
    );
  }

  static Widget _buildEditAccountPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final accountId = state.pathParameters[RouteNames.paramAccountId];
    final AssetAccount? account = state.extra is AssetAccount
        ? state.extra as AssetAccount
        : null;
    if (accountId == null) {
      log.severe("[AppRouter] Edit Account route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Account ID")),
      );
    }
    return AddEditAccountPage(accountId: accountId, account: account);
  }

  static Widget _buildEditBudgetPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final budgetId = state.pathParameters[RouteNames.paramId];
    final Budget? budget = state.extra is Budget ? state.extra as Budget : null;
    if (budgetId == null) {
      log.severe("[AppRouter] Edit Budget route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Budget ID")),
      );
    }
    return AddEditBudgetPage(initialBudget: budget);
  }

  static Widget _buildBudgetDetailPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final budgetId = state.pathParameters[RouteNames.paramId];
    if (budgetId == null) {
      log.severe("[AppRouter] Budget Detail route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Budget ID")),
      );
    }
    return BudgetDetailPage(budgetId: budgetId);
  }

  static Widget _buildEditGoalPage(BuildContext context, GoRouterState state) {
    final goalId = state.pathParameters[RouteNames.paramId];
    final Goal? goal = state.extra is Goal ? state.extra as Goal : null;
    if (goalId == null) {
      log.severe("[AppRouter] Edit Goal route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Goal ID")),
      );
    }
    return AddEditGoalPage(initialGoal: goal);
  }

  static Widget _buildGoalDetailPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final goalId = state.pathParameters[RouteNames.paramId];
    final Goal? goal = state.extra is Goal ? state.extra as Goal : null;
    if (goalId == null) {
      log.severe("[AppRouter] Goal Detail route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Goal ID")),
      );
    }
    return GoalDetailPage(goalId: goalId, initialGoal: goal);
  }
}

// --- GoRouterObserver (Unchanged) ---
class GoRouterObserver extends NavigatorObserver {
  // ... (Implementation unchanged) ...
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String pushedRoute =
        route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName =
        previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine('GoRouter Pushed: ${previousRouteName ?? 'null'} -> $pushedRoute');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String poppedRoute =
        route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName =
        previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine(
      'GoRouter Popped: $poppedRoute -> Returning to ${previousRouteName ?? 'null'}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String removedRoute =
        route.settings.name ??
        route.settings.arguments?.toString() ??
        route.toString();
    final String? previousRouteName =
        previousRoute?.settings.name ??
        previousRoute?.settings.arguments?.toString();
    log.fine(
      'GoRouter Removed: $removedRoute (Previous was: ${previousRouteName ?? 'null'})',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final String oldRouteName =
        oldRoute?.settings.name ??
        oldRoute?.settings.arguments?.toString() ??
        'null';
    final String newRouteName =
        newRoute?.settings.name ??
        newRoute?.settings.arguments?.toString() ??
        'null';
    log.fine('GoRouter Replaced: $oldRouteName with $newRouteName');
  }
}
