import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_field.dart';

void main() {
  testWidgets('BridgeTextField renders correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BridgeTextField(
            label: 'Test Label',
          ),
        ),
      ),
    );
    expect(find.text('Test Label'), findsOneWidget);
  });
}
