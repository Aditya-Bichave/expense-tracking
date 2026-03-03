import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_badge.dart';

void main() {
  group('AppBadge', () {
    testWidgets('renders basic badge with primary type by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppBadge(label: 'New'),
          ),
        ),
      );

      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('renders all badge types correctly', (tester) async {
      for (final type in AppBadgeType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: AppBadge(
                label: type.name,
                type: type,
              ),
            ),
          ),
        );
        expect(find.text(type.name), findsOneWidget);
      }
    });
  });
}
