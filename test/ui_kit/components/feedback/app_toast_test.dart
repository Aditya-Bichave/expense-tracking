import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_toast.dart';

void main() {
  group('AppToast', () {
    testWidgets('shows snackbar with correct message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  AppToast.show(context, 'Test Toast Message');
                },
                child: const Text('Show Toast'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Toast'));
      await tester.pump();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Test Toast Message'), findsOneWidget);
    });

    for (final type in AppToastType.values) {
      testWidgets('supports ${type.name} type', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    AppToast.show(context, 'Toast ${type.name}', type: type);
                  },
                  child: Text('Show ${type.name}'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Show ${type.name}'));
        await tester.pump();

        expect(find.text('Toast ${type.name}'), findsOneWidget);
      });
    }
  });
}
