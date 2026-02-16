import 'package:expense_tracker/core/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SectionHeader', () {
    testWidgets('renders title in uppercase', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SectionHeader(title: 'my section'),
      );

      // ASSERT
      expect(find.text('MY SECTION'), findsOneWidget);
    });

    testWidgets('applies correct styling from theme', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SectionHeader(title: 'Test'),
      );

      // ACT
      final textWidget = tester.widget<Text>(find.text('TEST'));
      final theme = Theme.of(tester.element(find.byType(SectionHeader)));

      // ASSERT
      expect(textWidget.style?.color, theme.colorScheme.primary);
      expect(textWidget.style?.fontWeight, FontWeight.bold);
      expect(textWidget.style?.letterSpacing, 0.8);
    });

    testWidgets('applies custom padding', (tester) async {
      // ARRANGE
      const customPadding = EdgeInsets.all(30);
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const SectionHeader(title: 'Test', padding: customPadding),
      );

      // ACT
      final paddingWidget = tester.widget<Padding>(find.byType(Padding));

      // ASSERT
      expect(paddingWidget.padding, customPadding);
    });
  });
}
