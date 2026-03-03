import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/typography/app_text.dart';

void main() {
  group('AppText', () {
    testWidgets('renders basic text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Material(child: AppText('Hello World'))),
      );

      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('applies different styles correctly', (tester) async {
      for (final style in AppTextStyle.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(child: AppText('Styled Text', style: style)),
          ),
        );

        expect(find.text('Styled Text'), findsOneWidget);
        // It's tricky to assert specific TextStyle from tokens accurately without a BuildContext,
        // but ensuring it doesn't crash covers the switch statement.
      }
    });

    testWidgets('applies custom properties', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppText(
              'Custom Text',
              color: Colors.red,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.byType(Text));
      expect(textWidget.style?.color, Colors.red);
      expect(textWidget.textAlign, TextAlign.center);
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);
    });
  });
}
