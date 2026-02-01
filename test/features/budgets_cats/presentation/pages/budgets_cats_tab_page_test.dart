import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/budgets_cats/presentation/pages/budgets_cats_tab_page.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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

    // Default states
    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState());
    when(() => mockGoalListBloc.state).thenReturn(const GoalListState());
  });

  group('BudgetsAndCatsTabPage', () {
    testWidgets('renders TabBar with Budgets and Goals tabs', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const BudgetsAndCatsTabPage(),
        blocProviders: [
          BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
          BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
        ],
      );

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Budgets'), findsOneWidget);
      expect(find.text('Goals'), findsOneWidget);
    });

    testWidgets('shows BudgetsSubTab initially', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const BudgetsAndCatsTabPage(),
        blocProviders: [
          BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
          BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
        ],
      );

      // BudgetsSubTab content (e.g., "No Budgets Created Yet" if empty)
      expect(find.text('No Budgets Created Yet'), findsOneWidget);
    });

    testWidgets('shows GoalsSubTab when Goals tab is tapped', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const BudgetsAndCatsTabPage(),
        blocProviders: [
          BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
          BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
        ],
      );

      await tester.tap(find.text('Goals'));
      await tester.pumpAndSettle();

      // GoalsSubTab content (e.g., "No Savings Goals Yet" if empty)
      expect(find.text('No Savings Goals Yet'), findsOneWidget);
    });
  });
}
