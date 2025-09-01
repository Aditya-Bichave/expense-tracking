import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_list/category_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/liabilities/presentation/bloc/liability_list/liability_list_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list/transaction_list_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'mock_helpers.dart';

// Helper class for mocking GoRouter
class MockGoRouter extends Mock implements GoRouter {
  @override
  GoRouteInformationProvider get routeInformationProvider =>
      GoRouteInformationProvider(initialLocation: '/', initialExtra: null);

  @override
  GoRouteInformationParser get routeInformationParser =>
      GoRouter(routes: []).routeInformationParser;

  @override
  GoRouterDelegate get routerDelegate => GoRouter(routes: []).routerDelegate;

  @override
  BackButtonDispatcher get backButtonDispatcher =>
      GoRouter(routes: []).backButtonDispatcher;
}

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockLiabilityListBloc
    extends MockBloc<LiabilityListEvent, LiabilityListState>
    implements LiabilityListBloc {}

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockCategoryListBloc
    extends MockBloc<CategoryListEvent, CategoryListState>
    implements CategoryListBloc {}

class MockGoalListBloc extends MockBloc<GoalListEvent, GoalListState>
    implements GoalListBloc {}

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockLogContributionBloc
    extends MockBloc<LogContributionEvent, LogContributionState>
    implements LogContributionBloc {}

// The Test Harness Function
Future<void> pumpWidgetWithProviders({
  required WidgetTester tester,
  required Widget widget,
  // --- Mocks & Stubs ---
  SettingsState? settingsState, // Easily provide a specific settings state
  AccountListState? accountListState,
  AccountListBloc? accountListBloc,
  LiabilityListState? liabilityListState,
  LiabilityListBloc? liabilityListBloc,
  TransactionListState? transactionListState,
  TransactionListBloc? transactionListBloc,
  DashboardState? dashboardState,
  DashboardBloc? dashboardBloc,
  CategoryListState? categoryListState,
  CategoryListBloc? categoryListBloc,
  GoalListState? goalListState,
  GoalListBloc? goalListBloc,
  BudgetListState? budgetListState,
  BudgetListBloc? budgetListBloc,
  LogContributionState? logContributionState,
  MockLogContributionBloc? logContributionBloc,
  List<BlocProvider> blocProviders =
      const [], // For other feature-specific Blocs
  GetIt? getIt, // Pass a pre-configured service locator if needed
  GoRouter? router, // Optional router configuration
  bool settle = true,
}) async {
  // 1. Determine router configuration
  final routerConfig = router ??
      GoRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(body: widget),
          ),
        ],
      );

  // 2. Prepare the mock Blocs
  final mockSettingsBloc = MockSettingsBloc();
  whenListen(
    mockSettingsBloc,
    Stream.fromIterable([settingsState ?? const SettingsState()]),
    initialState: settingsState ?? const SettingsState(),
  );

  final mockAccountListBloc = accountListBloc ?? MockAccountListBloc();
  if (accountListBloc == null) {
    whenListen(
      mockAccountListBloc,
      Stream<AccountListState>.fromIterable(
          [accountListState ?? const AccountListInitial()]),
      initialState: accountListState ?? const AccountListInitial(),
    );
  }

  final mockLiabilityListBloc = liabilityListBloc ?? MockLiabilityListBloc();
  if (liabilityListBloc == null) {
    whenListen(
      mockLiabilityListBloc,
      Stream<LiabilityListState>.fromIterable(
          [liabilityListState ?? const LiabilityListInitial()]),
      initialState: liabilityListState ?? const LiabilityListInitial(),
    );
  }

  final mockTransactionListBloc =
      transactionListBloc ?? MockTransactionListBloc();
  if (transactionListBloc == null) {
    whenListen(
      mockTransactionListBloc,
      Stream<TransactionListState>.fromIterable(
          [transactionListState ?? const TransactionListState()]),
      initialState: transactionListState ?? const TransactionListState(),
    );
  }

  final mockDashboardBloc = dashboardBloc ?? MockDashboardBloc();
  if (dashboardBloc == null) {
    whenListen(
      mockDashboardBloc,
      Stream<DashboardState>.fromIterable(
          [dashboardState ?? const DashboardLoading()]),
      initialState: dashboardState ?? const DashboardLoading(),
    );
  }

  final mockCategoryListBloc = categoryListBloc ?? MockCategoryListBloc();
  if (categoryListBloc == null) {
    whenListen(
      mockCategoryListBloc,
      Stream<CategoryListState>.fromIterable(
          [categoryListState ?? const CategoryListInitial()]),
      initialState: categoryListState ?? const CategoryListInitial(),
    );
  }

  final mockGoalListBloc = goalListBloc ?? MockGoalListBloc();
  if (goalListBloc == null) {
    whenListen(
      mockGoalListBloc,
      Stream<GoalListState>.fromIterable(
          [goalListState ?? const GoalListInitial()]),
      initialState: goalListState ?? const GoalListInitial(),
    );
  }

  final mockBudgetListBloc = budgetListBloc ?? MockBudgetListBloc();
  if (budgetListBloc == null) {
    whenListen(
      mockBudgetListBloc,
      Stream<BudgetListState>.fromIterable(
          [budgetListState ?? const BudgetListInitial()]),
      initialState: budgetListState ?? const BudgetListInitial(),
    );
  }

  final mockLogContributionBloc =
      logContributionBloc ?? MockLogContributionBloc();
  if (logContributionBloc == null) {
    whenListen(
      mockLogContributionBloc,
      Stream<LogContributionState>.fromIterable(
          [logContributionState ?? const LogContributionInitial()]),
      initialState: logContributionState ?? const LogContributionInitial(),
    );
  }

  // 3. Wrap the widget in all necessary providers
  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: mockSettingsBloc),
        BlocProvider<AccountListBloc>.value(value: mockAccountListBloc),
        BlocProvider<LiabilityListBloc>.value(value: mockLiabilityListBloc),
        BlocProvider<TransactionListBloc>.value(value: mockTransactionListBloc),
        BlocProvider<DashboardBloc>.value(value: mockDashboardBloc),
        BlocProvider<CategoryListBloc>.value(value: mockCategoryListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<LogContributionBloc>.value(
            value: mockLogContributionBloc),
        ...blocProviders,
      ],
      child: MaterialApp.router(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.buildTheme(
          settingsState?.uiMode ?? UIMode.elemental,
          settingsState?.paletteIdentifier ?? AppTheme.elementalPalette1,
        ).light,
        darkTheme: AppTheme.buildTheme(
          settingsState?.uiMode ?? UIMode.elemental,
          settingsState?.paletteIdentifier ?? AppTheme.elementalPalette1,
        ).dark,
        themeMode: settingsState?.themeMode ?? ThemeMode.system,
        routerConfig: routerConfig,
      ),
    ),
  );

  if (settle) {
    await tester.pumpAndSettle();
  }
}
