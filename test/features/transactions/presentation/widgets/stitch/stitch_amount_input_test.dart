import 'package:expense_tracker/features/transactions/presentation/widgets/stitch/stitch_amount_input.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StitchAmountInput renders and accepts input', (
    WidgetTester tester,
  ) async {
    final controller = TextEditingController();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StitchAmountInput(controller: controller, currencySymbol: '\$'),
        ),
      ),
    );

    expect(find.text('\$'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123.45');
    expect(controller.text, equals('123.45'));
  });
}
