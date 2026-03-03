import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_divider.dart';

void main() {
  group('AppDivider', () {
    testWidgets('renders basic divider with defaults', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppDivider(),
          ),
        ),
      );

      final dividerFinder = find.byType(Divider);
      expect(dividerFinder, findsOneWidget);

      final divider = tester.widget<Divider>(dividerFinder);
      expect(divider.height, 16.0);
      expect(divider.thickness, 1.0);
    });

    testWidgets('applies custom properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppDivider(
              height: 20.0,
              thickness: 2.0,
              color: Colors.red,
              indent: 10.0,
              endIndent: 10.0,
            ),
          ),
        ),
      );

      final dividerFinder = find.byType(Divider);
      expect(dividerFinder, findsOneWidget);

      final divider = tester.widget<Divider>(dividerFinder);
      expect(divider.height, 20.0);
      expect(divider.thickness, 2.0);
      expect(divider.color, Colors.red);
      expect(divider.indent, 10.0);
      expect(divider.endIndent, 10.0);
    });
  });
}
