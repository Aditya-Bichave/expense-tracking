import 'package:expense_tracker/features/groups/presentation/widgets/stitch/invite_generation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'InviteGenerationSheet renders correctly and triggers onGenerate',
    (WidgetTester tester) async {
      String? generatedRole;
      int? generatedExpiry;
      int? generatedLimit;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InviteGenerationSheet(
              onGenerate: (role, expiry, limit) {
                generatedRole = role;
                generatedExpiry = expiry;
                generatedLimit = limit;
              },
            ),
          ),
        ),
      );

      expect(find.text('Invite Members'), findsOneWidget);
      expect(find.text('Role'), findsOneWidget);
      expect(find.text('Expires In'), findsOneWidget);
      expect(find.text('Usage Limit'), findsOneWidget);
      expect(find.text('Generate Link'), findsOneWidget);

      // Initial values
      expect(find.text('Member'), findsOneWidget);
      expect(find.text('7 Days'), findsOneWidget);
      expect(find.text('Unlimited'), findsOneWidget);

      // Change Role
      await tester.tap(find.text('Member'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Viewer').last);
      await tester.pumpAndSettle();

      // Change Expiry
      await tester.tap(find.text('7 Days'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('1 Day').last);
      await tester.pumpAndSettle();

      // Change Limit
      await tester.tap(find.text('Unlimited'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Single Use').last);
      await tester.pumpAndSettle();

      // Tap Generate
      await tester.tap(find.text('Generate Link'));
      await tester.pumpAndSettle();

      expect(
        generatedRole,
        'viewer',
      ); // Actually 'viewer' is the value, 'Viewer' is the text.
      // The dropdown value is 'viewer'.
      expect(generatedExpiry, 1);
      expect(generatedLimit, 1);
    },
  );
}
