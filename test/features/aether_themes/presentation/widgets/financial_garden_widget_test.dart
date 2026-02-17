import 'package:expense_tracker/features/aether_themes/presentation/widgets/financial_garden_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FinancialGardenWidget renders placeholder text', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FinancialGardenWidget()));

    expect(
      find.text('Financial Garden Dashboard\n(Coming Soon!)'),
      findsOneWidget,
    );
    expect(find.byType(Text), findsOneWidget);

    // Optional: Check style
    final textWidget = tester.widget<Text>(
      find.text('Financial Garden Dashboard\n(Coming Soon!)'),
    );
    expect(textWidget.style?.color, Colors.green);
  });
}
