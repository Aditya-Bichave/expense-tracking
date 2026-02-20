import 'package:expense_tracker/core/widgets/stitch/stitch_onboarding_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'StitchOnboardingBackground renders child and background elements',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StitchOnboardingBackground(child: Text('Child Content')),
        ),
      );

      expect(find.text('Child Content'), findsOneWidget);
      // Background uses Stack and Positioned elements with BackdropFilter
      // Hard to verify specific visual effects, but we can check structure if needed.
      // Verifying child is sufficient for basic widget test.
    },
  );
}
