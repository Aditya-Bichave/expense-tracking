import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_avatar.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppAvatar', () {
    testWidgets('renders initials when no imageUrl is provided', (
      tester,
    ) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppAvatar(initials: 'JD'),
      );
      expect(find.text('JD'), findsOneWidget);
    });

    testWidgets('renders different sizes', (tester) async {
      for (final size in [20.0, 40.0, 60.0]) {
        await pumpWidgetWithProviders(
          tester: tester,
          widget: AppAvatar(initials: 'T', size: size),
        );
        expect(find.text('T'), findsOneWidget);
      }
    });
  });
}
