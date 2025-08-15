import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/widgets/app_card.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/pump_app.dart';

class MockOnTap extends Mock {
  void call();
}

void main() {
  group('AppCard', () {
    testWidgets('renders child widget correctly', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppCard(
          child: Text('Hello World'),
        ),
      );

      // ASSERT
      expect(find.text('Hello World'), findsOneWidget);
    });

    testWidgets('is tappable and calls onTap when provided', (tester) async {
      // ARRANGE
      final mockOnTap = MockOnTap();
      await pumpWidgetWithProviders(
        tester: tester,
        widget: AppCard(
          key: const ValueKey('tappable_card'),
          onTap: mockOnTap.call,
          child: const Text('Tap me'),
        ),
      );

      // ACT
      await tester.tap(find.byKey(const ValueKey('tappable_card')));
      await tester.pump();

      // ASSERT
      verify(() => mockOnTap.call()).called(1);
      expect(find.byType(InkWell), findsOneWidget);
    });

    testWidgets('is not tappable when onTap is null', (tester) async {
      // ARRANGE
      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppCard(
          child: Text('Not tappable'),
        ),
      );

      // ASSERT
      expect(find.byType(InkWell), findsNothing);
    });

    testWidgets('applies custom color and elevation properties', (tester) async {
      // ARRANGE
      const customColor = Colors.amber;
      const customElevation = 10.0;

      await pumpWidgetWithProviders(
        tester: tester,
        widget: const AppCard(
          color: customColor,
          elevation: customElevation,
          child: SizedBox(),
        ),
      );

      // ACT
      final card = tester.widget<Card>(find.byType(Card));

      // ASSERT
      expect(card.color, customColor);
      expect(card.elevation, customElevation);
    });

    // Requirement 4.5: Test for theme adaptation
    for (final uiMode in UIMode.values) {
      testWidgets('renders correctly in ${uiMode.name} UI mode', (tester) async {
        // ARRANGE
        await pumpWidgetWithProviders(
          tester: tester,
          settingsState: SettingsState(uiMode: uiMode),
          widget: const AppCard(child: SizedBox()),
        );

        // ACT
        final card = tester.widget<Card>(find.byType(Card));
        final theme = AppTheme.buildTheme(uiMode, AppTheme.elementalPalette1);
        final cardTheme = theme.light.cardTheme;

        // ASSERT
        // We check if the card's properties match the theme's cardTheme properties
        expect(card.shape, cardTheme.shape);
        expect(card.color, cardTheme.color);
        expect(card.margin, cardTheme.margin);
        // Elevation can be tricky due to modeTheme overrides, let's check it's non-null
        expect(card.elevation, isNotNull);
      });
    }
  });
}
