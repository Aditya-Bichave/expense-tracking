import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_link_text.dart';

void main() {
  group('AppLinkText', () {
    testWidgets('renders text and applies default style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Material(child: AppLinkText('Click Me'))),
      );

      expect(find.text('Click Me'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.decoration, TextDecoration.underline);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AppLinkText('Click Me', onTap: () => tapped = true),
          ),
        ),
      );

      await tester.tap(find.text('Click Me'));
      expect(tapped, true);
    });

    testWidgets('respects provided style', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppLinkText('Click Me', style: TextStyle(fontSize: 24)),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.fontSize, 24);
      expect(textWidget.style?.decoration, TextDecoration.underline);
    });
  });
}
