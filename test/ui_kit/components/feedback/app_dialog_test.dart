import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_dialog.dart';
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';

void main() {
  group('AppDialog', () {
    testWidgets('renders basic dialog with title and content', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AppDialog(title: 'Test Title', content: 'Test Content'),
          ),
        ),
      );

      expect(find.text('Test Title'), findsOneWidget);
      expect(find.text('Test Content'), findsOneWidget);
    });

    testWidgets('renders contentWidget when provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AppDialog(
              title: 'Test Title',
              contentWidget: const Text('Custom Widget'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Widget'), findsOneWidget);
    });

    testWidgets('renders buttons and handles actions', (tester) async {
      bool confirmTapped = false;
      bool cancelTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AppDialog(
              title: 'Test Title',
              confirmLabel: 'Confirm',
              cancelLabel: 'Cancel',
              onConfirm: () => confirmTapped = true,
              onCancel: () => cancelTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Confirm'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Confirm'));
      expect(confirmTapped, true);

      await tester.tap(find.text('Cancel'));
      expect(cancelTapped, true);
    });

    testWidgets('AppDialog.show presents dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                AppDialog.show(
                  context: context,
                  title: 'Show Title',
                  content: 'Show Content',
                  confirmLabel: 'OK',
                );
              },
              child: const Text('Open Dialog'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Show Title'), findsOneWidget);
      expect(find.text('Show Content'), findsOneWidget);
      expect(find.text('OK'), findsOneWidget);

      // Tap default OK (onConfirm not provided) and pop might not happen without Navigator.pop
      // but test is just to show it renders.
    });
  });
}
