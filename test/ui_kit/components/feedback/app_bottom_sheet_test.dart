import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_bottom_sheet.dart';

void main() {
  group('AppBottomSheet', () {
    testWidgets('renders child widget', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppBottomSheet(child: Text('BottomSheet Content')),
          ),
        ),
      );

      expect(find.text('BottomSheet Content'), findsOneWidget);
    });

    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppBottomSheet(
              title: 'My Title',
              child: Text('BottomSheet Content'),
            ),
          ),
        ),
      );

      expect(find.text('My Title'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });

    testWidgets('AppBottomSheet.show presents bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppBottomSheet.show(
                  context: context,
                  title: 'Show Title',
                  child: const Text('Show Content'),
                );
              },
              child: const Text('Open Sheet'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Show Title'), findsOneWidget);
      expect(find.text('Show Content'), findsOneWidget);
    });
  });
}
