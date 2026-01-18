import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('PlaceholderScreen', () {
    testWidgets('renders feature name and placeholder texts', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const PlaceholderScreen(featureName: 'My Feature'),
      );

      // ASSERT
      expect(find.text('My Feature'), findsNWidgets(2)); // AppBar and Body
      expect(find.text('Feature In Progress'), findsOneWidget);
      expect(
          find.text(
              'This section is currently under development and will be available soon. Stay tuned!'),
          findsOneWidget);
    });

    testWidgets('does not show back button when it cannot pop', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const PlaceholderScreen(featureName: 'My Feature'),
      );

      // ASSERT
      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows back button and pops when it can pop', (tester) async {
      // ARRANGE
      final router = GoRouter(
        initialLocation: '/home',
        routes: [
          GoRoute(
              path: '/home',
              builder: (context, state) => Scaffold(
                    body: ElevatedButton(
                      onPressed: () => context.push('/placeholder'),
                      child: const Text('Go to Placeholder'),
                    ),
                  )),
          GoRoute(
              path: '/placeholder',
              builder: (context, state) =>
                  const PlaceholderScreen(featureName: 'My Feature')),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Navigate to the placeholder screen
      await tester.tap(find.text('Go to Placeholder'));
      await tester.pumpAndSettle();

      // ASSERT: Placeholder screen is now visible
      expect(find.byType(PlaceholderScreen), findsOneWidget);
      expect(find.byKey(const ValueKey('button_placeholder_back')),
          findsOneWidget);

      // ACT: Tap the back button
      await tester.tap(find.byKey(const ValueKey('button_placeholder_back')));
      await tester.pumpAndSettle();

      // ASSERT: We are back on the home screen
      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(find.text('Go to Placeholder'), findsOneWidget);
    });
  });
}
