import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/feedback/app_banner.dart';

void main() {
  group('AppBanner', () {
    testWidgets('renders message', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(child: AppBanner(message: 'Test Message')),
        ),
      );

      expect(find.text('Test Message'), findsOneWidget);
    });

    testWidgets('renders different types without crashing', (tester) async {
      for (final type in AppBannerType.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Material(
              child: AppBanner(message: 'Test Message', type: type),
            ),
          ),
        );
        expect(find.text('Test Message'), findsOneWidget);
      }
    });

    testWidgets('calls onDismiss when close icon is tapped', (tester) async {
      bool dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: AppBanner(
              message: 'Test Message',
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.close));
      expect(dismissed, true);
    });

    testWidgets('renders action widget if provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Material(
            child: AppBanner(
              message: 'Test Message',
              action: Text('Custom Action'),
            ),
          ),
        ),
      );

      expect(find.text('Custom Action'), findsOneWidget);
    });
  });
}
