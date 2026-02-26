import 'package:expense_tracker/core/widgets/placeholder_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  group('PlaceholderScreen', () {
    testWidgets('renders feature name and placeholder texts', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const PlaceholderScreen(featureName: 'My Feature'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.text('My Feature'), findsNWidgets(2)); // Title and Headline
      expect(find.text('Feature In Progress'), findsOneWidget);
      expect(find.byIcon(Icons.construction_rounded), findsOneWidget);
    });

    testWidgets('does not show back button when it cannot pop', (tester) async {
      final router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const PlaceholderScreen(featureName: 'Root'),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('shows back button and pops when it can pop', (tester) async {
      final GoRouter router = GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) =>
                const PlaceholderScreen(featureName: 'Root'),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) =>
                    const PlaceholderScreen(featureName: 'Detail'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      // Verify Root is present
      expect(find.text('Root'), findsWidgets);

      // Navigate to Detail
      router.go('/detail');
      await tester.pumpAndSettle();

      // Verify Detail is present
      expect(find.text('Detail'), findsWidgets);

      // Verify Back Button is present
      final backButton = find.byKey(const ValueKey('button_placeholder_back'));
      expect(backButton, findsOneWidget);

      // Pop
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Verify back to Root
      expect(find.text('Root'), findsWidgets);
      expect(find.text('Detail'), findsNothing);
    });
  });
}
