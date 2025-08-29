import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/add_edit_goal/add_edit_goal_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/pages/add_edit_goal_page.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockAddEditGoalBloc extends MockBloc<AddEditGoalEvent, AddEditGoalState>
    implements AddEditGoalBloc {}

void main() {
  late AddEditGoalBloc mockBloc;

  setUp(() {
    mockBloc = MockAddEditGoalBloc();
    sl.registerFactoryParam<AddEditGoalBloc, Goal?, void>(
        (param1, _) => mockBloc);
  });

  tearDown(() {
    sl.reset();
  });

  group('AddEditGoalPage', () {
    testWidgets('renders GoalForm and correct title for "Add" mode',
        (tester) async {
      when(() => mockBloc.state).thenReturn(const AddEditGoalState());
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditGoalPage(),
      );

      expect(find.text('Add Goal'), findsWidgets);
      expect(find.byType(GoalForm), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is loading',
        (tester) async {
      when(() => mockBloc.state).thenReturn(
          const AddEditGoalState(status: AddEditGoalStatus.loading));
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AddEditGoalPage(),
        settle: false,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows success snackbar when state is success', (tester) async {
      whenListen(
        mockBloc,
        Stream.fromIterable(
            [const AddEditGoalState(status: AddEditGoalStatus.success)]),
        initialState: const AddEditGoalState(),
      );
      await pumpWidgetWithProviders(
          tester: tester, widget: const AddEditGoalPage());
      await tester.pump(); // Let snackbar appear

      expect(find.text('Goal added successfully!'), findsOneWidget);
    });
  });
}
