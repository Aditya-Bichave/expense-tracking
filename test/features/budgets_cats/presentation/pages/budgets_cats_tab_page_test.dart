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
  });

  testWidgets('BudgetsAndCatsTabPage renders Tabs and SubTabs', (tester) async {
    when(() => mockBudgetListBloc.state).thenReturn(const BudgetListState());
    when(() => mockGoalListBloc.state).thenReturn(const GoalListState());

    await pumpWidgetWithProviders(
      tester: tester,
      widget: const BudgetsAndCatsTabPage(),
      blocProviders: [
        BlocProvider<BudgetListBloc>.value(value: mockBudgetListBloc),
        BlocProvider<GoalListBloc>.value(value: mockGoalListBloc),
      ],
    );

    expect(find.text('Budgets'), findsOneWidget);
    expect(find.text('Goals'), findsOneWidget);
    expect(find.byType(TabBarView), findsOneWidget);

    // Check that we can see content from BudgetsSubTab (e.g. Empty State text if empty)
    // BudgetListState() is empty by default.
    expect(find.text("No Budgets Created Yet"), findsOneWidget);
  });
}
