import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:go_router/go_router.dart';
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

  testWidgets(
      'BudgetsAndCatsTabPage renders correctly with default tab (Budgets)',
      (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState(
      status: BudgetListStatus.success,
      budgetsWithStatus: [],
    ));
    when(() => mockGoalListBloc.state).thenReturn(const GoalListState(
      status: GoalListStatus.success,
      goals: [],
    ));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const BudgetsAndCatsTabPage(),
      blocProviders: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
      ],
    );

    // Verify TabBar tabs
    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);

    // Verify "No Budgets Created Yet" is visible (Budgets tab active)
    expect(find.text('No Budgets Created Yet'), findsOneWidget);

    // Verify "No Savings Goals Yet" is NOT visible
    expect(find.text('No Savings Goals Yet'), findsNothing);
  });

  testWidgets('BudgetsAndCatsTabPage switches to Goals tab', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState(
      status: BudgetListStatus.success,
      budgetsWithStatus: [],
    ));
    when(() => mockGoalListBloc.state).thenReturn(const GoalListState(
      status: GoalListStatus.success,
      goals: [],
    ));

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const BudgetsAndCatsTabPage(),
      blocProviders: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
      ],
    );

    // Tap Goals tab
    await tester.tap(find.text('Goals'));
    await tester.pumpAndSettle();

    // Verify "No Savings Goals Yet" is visible
    expect(find.text('No Savings Goals Yet'), findsOneWidget);
  });

  testWidgets(
      'BudgetsAndCatsTabPage initializes with Goals tab when extra is provided',
      (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState(
      status: BudgetListStatus.success,
      budgetsWithStatus: [],
    ));
    when(() => mockGoalListBloc.state).thenReturn(const GoalListState(
      status: GoalListStatus.success,
      goals: [],
    ));

    // Construct a GoRouter that provides the extra data
    final router = GoRouter(
      initialLocation: '/budgets',
      initialExtra: {'initialTabIndex': 2}, // 2 is mapped to Goals
      routes: [
        GoRoute(
          path: '/budgets',
          builder: (context, state) => const BudgetsAndCatsTabPage(),
        ),
      ],
    );

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const SizedBox(), // Ignored because router is provided
      router: router,
      blocProviders: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
      ],
    );

    // Verify "No Savings Goals Yet" is visible immediately
    expect(find.text('No Savings Goals Yet'), findsOneWidget);
  });
}
