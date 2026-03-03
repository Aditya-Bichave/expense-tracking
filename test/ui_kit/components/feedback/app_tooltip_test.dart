import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_tooltip.dart';

void main() {
  group('AppTooltip', () {
    testWidgets('renders child and passes message to Tooltip', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppTooltip(
              message: 'Tooltip message',
              child: Text('Hover me'),
            ),
          ),
        ),
      );

      expect(find.text('Hover me'), findsOneWidget);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, 'Tooltip message');
    });

    testWidgets('applies custom decoration and textStyle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppTooltip(message: 'Test Tooltip', child: Icon(Icons.info)),
          ),
        ),
      );

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.decoration, isA<BoxDecoration>());
      expect(tooltip.textStyle, isA<TextStyle>());
    });
  });
}
