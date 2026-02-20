import 'package:expense_tracker/features/recurring_transactions/presentation/widgets/stitch/monthly_commitments_summary.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('MonthlyCommitmentsSummary renders correctly', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: MonthlyCommitmentsSummary())),
    );

    expect(find.text('TOTAL MONTHLY COMMITMENTS'), findsOneWidget);
    expect(find.text('\$1,275'), findsOneWidget); // Static data for now
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });
}
