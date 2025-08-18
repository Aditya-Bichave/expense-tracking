import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_form.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockOnSubmit extends Mock {
  void call(String name, double targetAmount, DateTime? targetDate,
      String? iconName, String? description);
}

void main() {
  late MockOnSubmit mockOnSubmit;

  final mockGoal = Goal(
    id: '1',
    name: 'Initial Goal',
    targetAmount: 2000,
    totalSaved: 0,
    targetDate: DateTime(2025),
    iconName: 'savings',
    description: 'Initial description',
    status: GoalStatus.active,
    createdAt: DateTime(2023),
  );

  setUp(() {
    mockOnSubmit = MockOnSubmit();
    when(() => mockOnSubmit.call(any(), any(), any(), any(), any()))
        .thenAnswer((_) {});
  });

  group('GoalForm', () {
    testWidgets('initializes correctly in "add" mode', (tester) async {
      await pumpWidgetWithProviders(
          tester: tester, widget: GoalForm(onSubmit: mockOnSubmit.call));
      expect(find.text('Add Goal'), findsOneWidget);
    });

    testWidgets('initializes correctly in "edit" mode', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: GoalForm(initialGoal: mockGoal, onSubmit: mockOnSubmit.call),
      );
      expect(find.text('Update Goal'), findsOneWidget);
      expect(find.text('Initial Goal'), findsOneWidget);
      expect(find.text('2000.00'), findsOneWidget);
      expect(find.text('Initial description'), findsOneWidget);
    });

    testWidgets('onSubmit is called with correct data when form is valid',
        (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: GoalForm(onSubmit: mockOnSubmit.call),
      );

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Goal Name'), 'New Goal');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Target Amount'), '3000');

      await tester.tap(find.byKey(const ValueKey('button_submit')));
      await tester.pump();

      verify(() => mockOnSubmit.call(
            'New Goal',
            3000.0,
            any(named: 'targetDate'),
            any(named: 'iconName'),
            any(named: 'description'),
          )).called(1);
    });
  });
}
