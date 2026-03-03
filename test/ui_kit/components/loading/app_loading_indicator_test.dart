import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/loading/app_loading_indicator.dart';

void main() {
  group('AppLoadingIndicator', () {
    testWidgets('renders CircularProgressIndicator with default size', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(home: Material(child: AppLoadingIndicator())),
      );

      final indicatorFinder = find.byType(CircularProgressIndicator);
      expect(indicatorFinder, findsOneWidget);

      final sizedBoxFinder = find
          .ancestor(of: indicatorFinder, matching: find.byType(SizedBox))
          .first;

      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, 24.0);
      expect(sizedBox.height, 24.0);
    });

    testWidgets('renders with custom size and color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppLoadingIndicator(size: 48.0, color: Colors.red),
          ),
        ),
      );

      final indicatorFinder = find.byType(CircularProgressIndicator);
      expect(indicatorFinder, findsOneWidget);

      final indicator = tester.widget<CircularProgressIndicator>(
        indicatorFinder,
      );
      expect(indicator.valueColor?.value, Colors.red);

      final sizedBoxFinder = find
          .ancestor(of: indicatorFinder, matching: find.byType(SizedBox))
          .first;

      final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
      expect(sizedBox.width, 48.0);
      expect(sizedBox.height, 48.0);
    });
  });
}
