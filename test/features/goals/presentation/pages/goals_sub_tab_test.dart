import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/constants/route_names.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/pages/goals_sub_tab.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockGoalListBloc extends MockBloc<GoalListEvent, GoalListState> implements GoalListBloc {}
class MockGoRouter extends Mock implements GoRouter {}

void main() {
  late GoalListBloc mockBloc;
  late MockGoRouter mockGoRouter;

  final mockGoals = [Goal(id: '1', name: 'Test Goal', targetAmount: 1000, totalSaved: 100)];

  setUp(() {
    mockBloc = MockGoalListBloc();
    mockGoRouter = MockGoRouter();
  });

  Widget buildTestWidget() {
    return BlocProvider.value(
      value: mockBloc,
      child: const GoalsSubTab(),
    );
  }

  group('GoalsSubTab', () {
    testWidgets('shows loading indicator', (tester) async {
      when(() => mockBloc.state).thenReturn(const GoalListState(status: GoalListStatus.loading));
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty state and handles button tap', (tester) async {
      when(() => mockBloc.state).thenReturn(const GoalListState(status: GoalListStatus.loaded));
      when(() => mockGoRouter.pushNamed(RouteNames.addGoal)).thenAnswer((_) async {});
      await pumpWidgetWithProviders(tester: tester, router: mockGoRouter, widget: buildTestWidget());

      expect(find.text('No Savings Goals Yet'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('button_addFirst')));
      verify(() => mockGoRouter.pushNamed(RouteNames.addGoal)).called(1);
    });

    testWidgets('renders a list of GoalCards', (tester) async {
      when(() => mockBloc.state).thenReturn(GoalListState(status: GoalListStatus.loaded, goals: mockGoals));
      await pumpWidgetWithProviders(tester: tester, widget: buildTestWidget());
      expect(find.byType(GoalCard), findsOneWidget);
    });

    testWidgets('FAB navigates to add page', (tester) async {
      when(() => mockBloc.state).thenReturn(const GoalListState(status: GoalListStatus.loaded));
      when(() => mockGoRouter.pushNamed(RouteNames.addGoal)).thenAnswer((_) async {});
      await pumpWidgetWithProviders(tester: tester, router: mockGoRouter, widget: buildTestWidget());

      await tester.tap(find.byKey(const ValueKey('fab_goals_add')));
      verify(() => mockGoRouter.pushNamed(RouteNames.addGoal)).called(1);
    });
  });
}
