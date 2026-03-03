import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_empty_state.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('renders title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(child: AppEmptyState(title: 'No Data')),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
    });

    testWidgets('renders subtitle when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppEmptyState(
              title: 'No Data',
              subtitle: 'Please check back later.',
            ),
          ),
        ),
      );

      expect(find.text('No Data'), findsOneWidget);
      expect(find.text('Please check back later.'), findsOneWidget);
    });

    testWidgets('renders icon when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppEmptyState(title: 'No Data', icon: Icons.error),
          ),
        ),
      );

      expect(find.byIcon(Icons.error), findsOneWidget);
    });

    testWidgets('renders custom illustration instead of icon', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppEmptyState(
              title: 'No Data',
              icon: Icons.error,
              customIllustration: Text('Custom Image'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Image'), findsOneWidget);
      expect(find.byIcon(Icons.error), findsNothing);
    });

    testWidgets('renders action widget when provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppEmptyState(
              title: 'No Data',
              action: ElevatedButton(onPressed: null, child: Text('Retry')),
            ),
          ),
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });
  });
}
