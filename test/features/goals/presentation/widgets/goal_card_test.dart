import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/presentation/widgets/goal_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/pump_app.dart';

class MockOnTap extends Mock {
  void call();
}

void main() {
  final mockGoal = Goal(
    id: '1',
    name: 'New Laptop',
    targetAmount: 1500,
    totalSaved: 750,
    targetDate: DateTime.now().add(const Duration(days: 100)),
  );

  group('GoalCard', () {
    testWidgets('renders goal name, amounts, and target date', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(child: GoalCard(goal: mockGoal)),
      );

      expect(find.text('New Laptop'), findsOneWidget);
      expect(find.textContaining('Saved'), findsOneWidget);
      expect(find.textContaining('Target'),
          findsNWidgets(2)); // Target amount and target date
      expect(find.textContaining('Remaining'), findsOneWidget);
    });

    testWidgets('onTap callback is called when tapped', (tester) async {
      final mockOnTap = MockOnTap();
      when(() => mockOnTap.call()).thenAnswer((_) {});

      await pumpWidgetWithProviders(
        tester: tester,
        widget:
            Material(child: GoalCard(goal: mockGoal, onTap: mockOnTap.call)),
      );

      await tester.tap(find.byType(AppCard));

      verify(() => mockOnTap.call()).called(1);
    });

    testWidgets('shows achieved chip when goal is achieved', (tester) async {
      final achievedGoal = mockGoal.copyWith(totalSaved: 1500);
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(child: GoalCard(goal: achievedGoal)),
      );

      expect(find.text('Achieved'), findsOneWidget);
      expect(find.text('Achieved!'), findsOneWidget); // Remaining text
    });
  });
}
