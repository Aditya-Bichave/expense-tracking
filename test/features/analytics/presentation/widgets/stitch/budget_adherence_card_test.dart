import 'package:expense_tracker/features/analytics/presentation/widgets/stitch/budget_adherence_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('BudgetAdherenceCard renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BudgetAdherenceCard(), // No parameters
        ),
      ),
    );

    expect(find.text('BUDGET ADHERENCE'), findsOneWidget);
    expect(find.text('On Track'), findsOneWidget);
  });
}
