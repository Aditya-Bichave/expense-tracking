import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/stitch/recurring_payment_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('RecurringPaymentItem renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: RecurringPaymentItem(
            title: 'Netflix',
            schedule: 'Monthly',
            date: '15th',
            amount: '\$15.99',
            status: 'Upcoming',
            icon: Icons.movie,
            color: Colors.red,
          ),
        ),
      ),
    );

    expect(find.text('Netflix'), findsOneWidget);
    expect(find.text('Monthly • 15th'), findsOneWidget);
    expect(find.text('\$15.99'), findsOneWidget);
    expect(find.text('Upcoming'), findsOneWidget);
    expect(find.byIcon(Icons.movie), findsOneWidget);
  });
}
