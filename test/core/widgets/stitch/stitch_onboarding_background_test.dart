import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/widgets/stitch/stitch_onboarding_background.dart';

void main() {
  testWidgets(
    'StitchOnboardingBackground renders child and background elements',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: StitchOnboardingBackground(child: const Text('Test Child')),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
      expect(find.byType(Stack), findsOneWidget);

      // Check for "Orbs" (Positioned Containers with specific decorations)
      // It's hard to find exact containers by decoration without keys.
      // We can just verify the structure is there.

      // There should be at least 3 children in the Stack (Background, Orb1, Orb2, Child) -> 4 children actually
      // But `Stack` doesn't expose children count easily to finder.

      // We can verify that we have Positioned widgets.
      expect(find.byType(Positioned), findsAtLeastNWidgets(2));
    },
  );
}
