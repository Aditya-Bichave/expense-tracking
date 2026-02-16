import 'package:expense_tracker/core/widgets/settings_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockOnTap extends Mock {
  void call();
}

void main() {
  group('SettingsListTile', () {
    testWidgets('renders title, subtitle, and icons', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const Material(
          child: SettingsListTile(
            title: 'My Title',
            subtitle: 'My Subtitle',
            leadingIcon: Icons.settings,
            trailing: Icon(Icons.arrow_forward_ios),
          ),
        ),
      );

      // ASSERT
      expect(find.text('My Title'), findsOneWidget);
      expect(find.text('My Subtitle'), findsOneWidget);
      expect(find.byIcon(Icons.settings), findsOneWidget);
      expect(find.byIcon(Icons.arrow_forward_ios), findsOneWidget);
    });

    testWidgets('is tappable and calls onTap when enabled', (tester) async {
      // ARRANGE
      final mockOnTap = MockOnTap();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: SettingsListTile(
            key: const ValueKey('settings_tile'),
            title: 'Test',
            leadingIcon: Icons.abc,
            onTap: mockOnTap.call,
            enabled: true,
          ),
        ),
      );

      // ACT
      await tester.tap(find.byKey(const ValueKey('settings_tile')));
      await tester.pump();

      // ASSERT
      verify(() => mockOnTap.call()).called(1);
    });

    testWidgets('is not tappable when disabled', (tester) async {
      // ARRANGE
      final mockOnTap = MockOnTap();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: Material(
          child: SettingsListTile(
            key: const ValueKey('settings_tile'),
            title: 'Test',
            leadingIcon: Icons.abc,
            onTap: mockOnTap.call,
            enabled: false,
          ),
        ),
      );

      // ACT
      await tester.tap(find.byKey(const ValueKey('settings_tile')));
      await tester.pump();

      // ASSERT
      verifyNever(() => mockOnTap.call());
    });

    testWidgets('applies disabled styling when disabled', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const Material(
          child: SettingsListTile(
            title: 'Disabled Title',
            leadingIcon: Icons.disabled_by_default,
            enabled: false,
          ),
        ),
      );

      // ACT
      final theme = Theme.of(tester.element(find.byType(SettingsListTile)));
      final tile = tester.widget<ListTile>(find.byType(ListTile));
      final titleText = tester.widget<Text>(find.text('Disabled Title'));
      final leadingIcon = tester.widget<Icon>(
        find.byIcon(Icons.disabled_by_default),
      );

      // ASSERT
      expect(tile.enabled, isFalse);
      expect(titleText.style?.color, theme.disabledColor);
      expect(leadingIcon.color, theme.disabledColor);
    });
  });
}
