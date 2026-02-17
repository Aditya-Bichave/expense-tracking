import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockGoalListBloc extends MockBloc<GoalListEvent, GoalListState>
    implements GoalListBloc {}

void main() {
  late MockBudgetListBloc mockBudgetListBloc;
  late MockGoalListBloc mockGoalListBloc;

  setUp(() {
    mockBudgetListBloc = MockBudgetListBloc();
    mockGoalListBloc = MockGoalListBloc();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Map<String, dynamic>? extra,
    bool settle = true,
  }) async {
    final router = GoRouter(
      initialLocation: '/',
      initialExtra: extra,
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BudgetsAndCatsTabPage(),
          routes: [
            GoRoute(
              path: 'add_budget', // Relative path from /
              name: RouteNames.addBudget,
              builder: (context, state) =>
                  const Scaffold(body: Text('Add Budget Page')),
            ),
            GoRoute(
              path: 'add_goal', // Relative path from /
              name: RouteNames.addGoal,
              builder: (context, state) =>
                  const Scaffold(body: Text('Add Goal Page')),
            ),
            GoRoute(
              path: 'budget_detail/:id',
              name: RouteNames.budgetDetail,
              builder: (context, state) =>
                  const Scaffold(body: Text('Budget Detail Page')),
            ),
            GoRoute(
              path: 'goal_detail/:id',
              name: RouteNames.goalDetail,
              builder: (context, state) =>
                  const Scaffold(body: Text('Goal Detail Page')),
            ),
          ],
        ),
      ],
    );

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SizedBox(), // Ignored when router is provided
      router: router,
      settle: settle,
      blocProviders: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
      ],
    );
  }

  testWidgets('renders Budgets and Goals tabs', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.loading,
        budgetsWithStatus: [],
      ),
    );
    when(() => mockGoalListBloc.state).thenReturn(
      const GoalListState(status: GoalListStatus.loading, goals: []),
    );

    await pumpPage(tester, settle: false);

    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
  });

  testWidgets('defaults to Budgets tab (empty state)', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [],
      ),
    );
    when(() => mockGoalListBloc.state).thenReturn(
      const GoalListState(status: GoalListStatus.success, goals: []),
    );

    await pumpPage(tester);

    expect(find.text('No Budgets Created Yet'), findsOneWidget);
    expect(find.text('No Savings Goals Yet'), findsNothing);
  });

  testWidgets('switches to Goals tab (empty state)', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [],
      ),
    );
    when(() => mockGoalListBloc.state).thenReturn(
      const GoalListState(status: GoalListStatus.success, goals: []),
    );

    await pumpPage(tester);

    // Tap Goals tab
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();

    expect(find.text('No Savings Goals Yet'), findsOneWidget);
    expect(find.text('No Budgets Created Yet'), findsNothing);
  });

  testWidgets('initializes with Goals tab if extra index is 2', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [],
      ),
    );
    when(() => mockGoalListBloc.state).thenReturn(
      const GoalListState(status: GoalListStatus.success, goals: []),
    );

    await pumpPage(tester, extra: {'initialTabIndex': 2});

    expect(find.text('No Savings Goals Yet'), findsOneWidget);
    expect(find.text('No Budgets Created Yet'), findsNothing);
  });

  testWidgets('navigates to Add Budget page', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [],
      ),
    );
    when(() => mockGoalListBloc.state).thenReturn(
      const GoalListState(status: GoalListStatus.success, goals: []),
    );

    await pumpPage(tester);

    // Tap Add First Budget button (empty state)
    await tester.tap(find.byKey(const ValueKey('button_budgetList_addFirst')));
    await tester.pumpAndSettle();

    expect(find.text('Add Budget Page'), findsOneWidget);
  });

  testWidgets('navigates to Add Goal page', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(
      const BudgetListState(
        status: BudgetListStatus.success,
        budgetsWithStatus: [],
      ),
    );
    when(() => mockGoalListBloc.state).thenReturn(
      const GoalListState(status: GoalListStatus.success, goals: []),
    );

    await pumpPage(tester, extra: {'initialTabIndex': 2}); // Start on Goals tab

    // Tap Add First Goal button (empty state)
    await tester.tap(find.byKey(const ValueKey('button_addFirst')));
    await tester.pumpAndSettle();

    expect(find.text('Add Goal Page'), findsOneWidget);
  });
}
