import 'package:expense_tracker/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('showStrongConfirmation confirms only on exact phrase', (
    tester,
  ) async {
    bool? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () async {
              result = await AppDialogs.showStrongConfirmation(
                context,
                title: 'Delete',
                content: 'Type DELETE',
                confirmText: 'Delete',
                confirmationPhrase: 'DELETE',
              );
            },
            child: const Text('open'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // Confirm button should be disabled initially
    final confirmButton = find.widgetWithText(TextButton, 'Delete');
    expect(tester.widget<TextButton>(confirmButton).onPressed, isNull);

    await tester.enterText(find.byType(TextFormField), 'DELETE');
    await tester.pump();
    expect(tester.widget<TextButton>(confirmButton).onPressed, isNotNull);

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });
}
