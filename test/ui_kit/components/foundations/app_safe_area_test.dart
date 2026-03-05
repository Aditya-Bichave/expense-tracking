import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_safe_area.dart';
import '../../../helpers/pump_app.dart';

void main() {
  group('AppSafeArea', () {
    testWidgets('wraps child in SafeArea', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppSafeArea(child: Text('Safe Child')),
      );

      expect(find.byType(SafeArea), findsOneWidget);
      expect(find.text('Safe Child'), findsOneWidget);
    });

    testWidgets('respects parameters', (tester) async {
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppSafeArea(
          top: false,
          bottom: true,
          left: false,
          right: true,
          child: Text('Safe Child'),
        ),
      );

      final SafeArea safeArea = tester.widget(find.byType(SafeArea));
      expect(safeArea.top, isFalse);
      expect(safeArea.bottom, isTrue);
      expect(safeArea.left, isFalse);
      expect(safeArea.right, isTrue);
    });
  });
}
