import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FinancialGardenWidget renders coming soon text', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: FinancialGardenWidget()),
    ));

    expect(find.textContaining('Financial Garden Dashboard'), findsOneWidget);
    expect(find.textContaining('Coming Soon'), findsOneWidget);
  });
}
