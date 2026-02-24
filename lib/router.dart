// lib/router.dart
import 'dart:async';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
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
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/pages/settings_page.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/add_edit_transaction_page.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:expense_tracker/features/transactions/presentation/pages/transaction_list_page.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/main_shell.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:expense_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:expense_tracker/features/auth/presentation/pages/verify_otp_page.dart';
import 'package:expense_tracker/features/groups/presentation/pages/group_list_page.dart';
import 'package:expense_tracker/features/groups/presentation/pages/group_detail_page.dart';
import 'package:expense_tracker/features/profile/presentation/pages/profile_setup_page.dart';
import 'package:expense_tracker/features/auth/presentation/pages/lock_screen.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  GoRouterRefreshStream(List<Stream<dynamic>> streams) {
    notifyListeners();
    _subscriptions = streams
        .map(
          (stream) => stream.asBroadcastStream().listen(
            (dynamic _) => notifyListeners(),
          ),
        )
        .toList();
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: RouteNames.initialSetup,
    refreshListenable: GoRouterRefreshStream([
      sl<SessionCubit>().stream,
      sl<SettingsBloc>().stream,
    ]),
    redirect: (context, state) {
      final sessionState = sl<SessionCubit>().state;
      final settingsState = sl<SettingsBloc>().state;
      final location = state.uri.toString();
      final isLoggingIn =
          location == RouteNames.login ||
          location == RouteNames.initialSetup ||
          location.startsWith(RouteNames.verifyOtp);

      if (sessionState is SessionLocked) {
        if (location != '/lock') return '/lock';
        return null;
      }

      final isGuestMode =
          settingsState.setupSkipped || settingsState.isInDemoMode;

      if (sessionState is SessionUnauthenticated) {
        if (isGuestMode) {
          if (location == RouteNames.initialSetup) return RouteNames.dashboard;
          return null;
        }
        if (isLoggingIn) return null;
        return RouteNames.initialSetup;
      }

      if (sessionState is SessionNeedsProfileSetup) {
        if (location != '/profile-setup') return '/profile-setup';
        return null;
      }

      if (sessionState is SessionAuthenticated) {
        if (isLoggingIn ||
            location == '/lock' ||
            location == '/profile-setup') {
          return RouteNames.dashboard;
        }
        return null;
      }

      return null;
    },
    observers: [GoRouterObserver()],
    routes: [
      GoRoute(path: '/lock', builder: (context, state) => const LockScreen()),
      GoRoute(
        path: '/profile-setup',
        builder: (context, state) => const ProfileSetupPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.verifyOtp,
        builder: (context, state) =>
            VerifyOtpPage(phone: (state.extra as String?) ?? ''),
      ),

      GoRoute(
        path: RouteNames.initialSetup,
        name: RouteNames.initialSetup,
        builder: (context, state) => const InitialSetupScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
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
          StatefulShellBranch(
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
                      String? merchantIdFromExtra;
                      if (state.extra is String) {
                        merchantIdFromExtra = state.extra as String;
                      } else if (state.extra is Map) {
                        merchantIdFromExtra =
                            (state.extra as Map)['merchantId'];
                      }
                      return AddEditTransactionPage(
                        merchantId: merchantId ?? merchantIdFromExtra,
                      );
                    },
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.editTransaction}/:${RouteNames.paramTransactionId}',
                    name: RouteNames.editTransaction,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        _buildEditTransactionPage(context, state),
                  ),
                  GoRoute(
                    path:
                        '${RouteNames.transactionDetail}/:${RouteNames.paramTransactionId}',
                    name: RouteNames.transactionDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        _buildTransactionDetailPage(context, state),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RouteNames.groups,
                name: RouteNames.groups,
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: GroupListPage()),
                routes: [
                  GoRoute(
                    path: ':id',
                    name: RouteNames.groupDetail,
                    builder: (context, state) =>
                        GroupDetailPage(groupId: state.pathParameters['id']!),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
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
                        builder: (context, state) =>
                            _buildEditCategoryPage(context, state),
                      ),
                    ],
                  ),
                  GoRoute(
                    path: RouteNames.addBudget,
                    name: RouteNames.addBudget,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditBudgetPage(),
                  ),
                  GoRoute(
                    path: '${RouteNames.editBudget}/:${RouteNames.paramId}',
                    name: RouteNames.editBudget,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        _buildEditBudgetPage(context, state),
                  ),
                  GoRoute(
                    path: '${RouteNames.budgetDetail}/:${RouteNames.paramId}',
                    name: RouteNames.budgetDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        _buildBudgetDetailPage(context, state),
                  ),
                  GoRoute(
                    path: RouteNames.addGoal,
                    name: RouteNames.addGoal,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) => const AddEditGoalPage(),
                  ),
                  GoRoute(
                    path: '${RouteNames.editGoal}/:${RouteNames.paramId}',
                    name: RouteNames.editGoal,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        _buildEditGoalPage(context, state),
                  ),
                  GoRoute(
                    path: '${RouteNames.goalDetail}/:${RouteNames.paramId}',
                    name: RouteNames.goalDetail,
                    parentNavigatorKey: _rootNavigatorKey,
                    builder: (context, state) =>
                        _buildGoalDetailPage(context, state),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
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
                    builder: (context, state) =>
                        _buildEditAccountPage(context, state),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
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
                    builder: (context, state) =>
                        const AddEditRecurringRulePage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
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

  static List<RouteBase> _buildReportSubRoutes(
    GlobalKey<NavigatorState> parentKey,
  ) {
    return [
      GoRoute(
        path: RouteNames.reportSpendingCategory,
        name: RouteNames.reportSpendingCategory,
        parentNavigatorKey: parentKey,
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
    if (id == null) {
      log.severe("[AppRouter] Txn Detail route missing ID!");
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text("Error: Could not load transaction details"),
        ),
      );
    }
    if (transaction != null && transaction.id != id) {
      log.warning(
        "[AppRouter] Txn Detail route ID mismatch (Path: $id, Extra: ${transaction.id}). Ignoring extra.",
      );
      transaction = null;
    }
    return TransactionDetailPage(transactionId: id, transaction: transaction);
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
    // Validate ID if initialData has one
    String? extraId;
    if (initialData is TransactionEntity)
      extraId = initialData.id;
    else if (initialData is Expense)
      extraId = initialData.id;
    else if (initialData is Income)
      extraId = initialData.id;

    if (transactionId != null && extraId != null && transactionId != extraId) {
      log.warning(
        "[AppRouter] Edit Txn route ID mismatch (Path: $transactionId, Extra: $extraId). Ignoring extra.",
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
    Category? category = state.extra is Category
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
    if (category != null && category.id != categoryId) {
      log.warning(
        "[AppRouter] Edit Category route ID mismatch (Path: $categoryId, Extra: ${category.id}). Ignoring extra.",
      );
      category = null;
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
    AssetAccount? account = state.extra is AssetAccount
        ? state.extra as AssetAccount
        : null;
    if (accountId == null) {
      log.severe("[AppRouter] Edit Account route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Account ID")),
      );
    }
    if (account != null && account.id != accountId) {
      log.warning(
        "[AppRouter] Edit Account route ID mismatch (Path: $accountId, Extra: ${account.id}). Ignoring extra.",
      );
      account = null;
    }
    return AddEditAccountPage(accountId: accountId, account: account);
  }

  static Widget _buildEditBudgetPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final budgetId = state.pathParameters[RouteNames.paramId];
    Budget? budget = state.extra is Budget ? state.extra as Budget : null;
    if (budgetId == null) {
      log.severe("[AppRouter] Edit Budget route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Budget ID")),
      );
    }
    if (budget != null && budget.id != budgetId) {
      log.warning(
        "[AppRouter] Edit Budget route ID mismatch (Path: $budgetId, Extra: ${budget.id}). Ignoring extra.",
      );
      budget = null;
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
    Goal? goal = state.extra is Goal ? state.extra as Goal : null;
    if (goalId == null) {
      log.severe("[AppRouter] Edit Goal route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Goal ID")),
      );
    }
    if (goal != null && goal.id != goalId) {
      log.warning(
        "[AppRouter] Edit Goal route ID mismatch (Path: $goalId, Extra: ${goal.id}). Ignoring extra.",
      );
      goal = null;
    }
    return AddEditGoalPage(initialGoal: goal);
  }

  static Widget _buildGoalDetailPage(
    BuildContext context,
    GoRouterState state,
  ) {
    final goalId = state.pathParameters[RouteNames.paramId];
    Goal? goal = state.extra is Goal ? state.extra as Goal : null;
    if (goalId == null) {
      log.severe("[AppRouter] Goal Detail route called without ID!");
      return const Scaffold(
        appBar: null,
        body: Center(child: Text("Error: Missing Goal ID")),
      );
    }
    if (goal != null && goal.id != goalId) {
      log.warning(
        "[AppRouter] Goal Detail route ID mismatch (Path: $goalId, Extra: ${goal.id}). Ignoring extra.",
      );
      goal = null;
    }
    return GoalDetailPage(goalId: goalId, initialGoal: goal);
  }
}

class GoRouterObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String pushedRoute =
        route.settings.name ??
        _sanitizeArgs(route.settings.arguments) ??
        route.toString();
    final String? previousRouteName =
        previousRoute?.settings.name ??
        _sanitizeArgs(previousRoute?.settings.arguments);
    log.fine('GoRouter Pushed: ${previousRouteName ?? 'null'} -> $pushedRoute');
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String poppedRoute =
        route.settings.name ??
        _sanitizeArgs(route.settings.arguments) ??
        route.toString();
    final String? previousRouteName =
        previousRoute?.settings.name ??
        _sanitizeArgs(previousRoute?.settings.arguments);
    log.fine(
      'GoRouter Popped: $poppedRoute -> Returning to ${previousRouteName ?? 'null'}',
    );
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    final String removedRoute =
        route.settings.name ??
        _sanitizeArgs(route.settings.arguments) ??
        route.toString();
    final String? previousRouteName =
        previousRoute?.settings.name ??
        _sanitizeArgs(previousRoute?.settings.arguments);
    log.fine(
      'GoRouter Removed: $removedRoute (Previous was: ${previousRouteName ?? 'null'})',
    );
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final String oldRouteName =
        oldRoute?.settings.name ??
        _sanitizeArgs(oldRoute?.settings.arguments) ??
        'null';
    final String newRouteName =
        newRoute?.settings.name ??
        _sanitizeArgs(newRoute?.settings.arguments) ??
        'null';
    log.fine('GoRouter Replaced: $oldRouteName with $newRouteName');
  }

  String? _sanitizeArgs(Object? args) {
    if (args == null) return null;
    if (args is String || args is num || args is bool) {
      return args.toString();
    }
    // For complex objects, only log the type to prevent PII leakage
    return '<${args.runtimeType}>';
  }
}
