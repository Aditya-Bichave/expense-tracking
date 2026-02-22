import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/widgets/lock_screen.dart';

void main() {
  testWidgets('LockScreen renders correctly', (WidgetTester tester) async {
    bool authenticated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: LockScreen(
          onAuthenticate: () {
            authenticated = true;
          },
        ),
      ),
    );

    // Verify UI elements
    expect(find.text('App Locked'), findsOneWidget);
    expect(find.text('Please authenticate to continue'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    expect(find.text('Unlock'), findsOneWidget);

    // Verify interactions
    await tester.tap(find.text('Unlock'));
    expect(authenticated, true);
  });
}
