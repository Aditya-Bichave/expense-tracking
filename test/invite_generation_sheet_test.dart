import 'package:expense_tracker/features/groups/presentation/widgets/stitch/invite_generation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('InviteGenerationSheet renders and handles interactions safely', (
    tester,
  ) async {
    bool generated = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InviteGenerationSheet(
            onGenerate: (role, expiry, limit) {
              generated = true;
            },
          ),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Invite Members'), findsOneWidget);
    expect(find.text('Member'), findsOneWidget); // Default role
    expect(find.text('7 Days'), findsOneWidget); // Default expiry

    // Interact with dropdowns (simulating selection)
    // Finding dropdowns is tricky, but we can tap them.

    // Tap the 'Generate Link' button
    await tester.tap(find.text('Generate Link'));
    await tester.pumpAndSettle();

    expect(generated, isTrue);
  });
}
