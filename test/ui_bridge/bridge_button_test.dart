import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_bridge/bridge_button.dart';

void main() {
  testWidgets('BridgeButton renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BridgeButton(
            label: 'Test Button',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(find.text('Test Button'), findsOneWidget);
  });
}
