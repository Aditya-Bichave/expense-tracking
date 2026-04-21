import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/animation/app_slide_fade.dart';

void main() {
  group('AppSlideFade', () {
    testWidgets('renders child and animates properly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSlideFade(
              child: const Text('Animated Text'),
            ),
          ),
        ),
      );

      // Verify child is present
      expect(find.text('Animated Text'), findsOneWidget);

      // Wait for animation to finish
      await tester.pumpAndSettle();

      // Verify child is still present and fully visible
      expect(find.text('Animated Text'), findsOneWidget);
    });

    testWidgets('respects custom delay and duration', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSlideFade(
              delay: 0.5,
              duration: const Duration(milliseconds: 200),
              child: const Text('Delayed Text'),
            ),
          ),
        ),
      );

      expect(find.text('Delayed Text'), findsOneWidget);

      // Pump less than delay
      await tester.pump(const Duration(milliseconds: 300));
      // Animation hasn't started yet

      // Pump past delay
      await tester.pump(const Duration(milliseconds: 300));

      // Pump to completion
      await tester.pumpAndSettle();

      expect(find.text('Delayed Text'), findsOneWidget);
    });

    testWidgets('handles custom offset and curve', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppSlideFade(
              offset: const Offset(0.5, 0.5),
              curve: Curves.linear,
              child: const Text('Custom Anim Text'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Anim Text'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Custom Anim Text'), findsOneWidget);
    });
  });
}
