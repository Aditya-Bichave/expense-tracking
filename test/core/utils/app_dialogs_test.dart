import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppDialogs', () {
    testWidgets(
      'showConfirmation shows dialog with correct title and content',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => AppDialogs.showConfirmation(
                  context,
                  title: 'Test Title',
                  content: 'Test Content',
                  confirmText: 'Yes',
                ),
                child: const Text('Show'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show'));
        await tester.pumpAndSettle();

        expect(find.text('Test Title'), findsOneWidget);
        expect(find.text('Test Content'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
      },
    );

    testWidgets('showConfirmation returns true on confirm', (tester) async {
      bool? result;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                result = await AppDialogs.showConfirmation(
                  context,
                  title: 'T',
                  content: 'C',
                  confirmText: 'OK',
                );
              },
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(result, true);
    });

    testWidgets('showStrongConfirmation requires exact phrase', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => AppDialogs.showStrongConfirmation(
                context,
                title: 'Delete',
                content: 'Are you sure?',
                confirmText: 'DELETE',
                confirmationPhrase: 'confirm me',
              ),
              child: const Text('Show'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show'));
      await tester.pumpAndSettle();

      final confirmBtn = find.widgetWithText(TextButton, 'DELETE');

      // Button should be disabled initially (or doing nothing)
      // The implementation checks controller text in onPressed.
      // If we tap it without text, it should not pop.
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget); // Still open

      // Enter wrong text
      await tester.enterText(find.byType(TextFormField), 'wrong');
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsOneWidget); // Still open

      // Enter correct text
      await tester.enterText(find.byType(TextFormField), 'confirm me');
      await tester.pumpAndSettle();
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();
      expect(find.text('Delete'), findsNothing); // Popped
    });
  });
}
