import 'package:expense_tracker/features/analytics/presentation/widgets/stitch/spending_trends_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SpendingTrendsChart renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SpendingTrendsChart())),
    );

    expect(find.text('SPENDING TRENDS'), findsOneWidget);
    expect(find.text('\$2,450.00'), findsOneWidget);
    // Finds at least one CustomPaint (the chart)
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(1));
    expect(find.text('Mon'), findsOneWidget);
  });
}
