import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart'; // Use UI Kit component
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppCard', () {
    testWidgets('renders child widget correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppCard(child: Text('Test Child'))),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('is tappable and calls onTap when provided', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Tap Me'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Tap Me'));
      expect(tapped, true);
    });

    testWidgets('is not tappable when onTap is null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: AppCard(child: Text('No Tap'))),
        ),
      );

      final inkWell = find.byType(InkWell);
      expect(inkWell, findsNothing);
    });

    testWidgets('applies custom color and elevation properties', (
      tester,
    ) async {
      const customColor = Colors.red;
      const customElevation = 10.0;

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppCard(
              color: customColor,
              elevation: customElevation,
              child: SizedBox(),
            ),
          ),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.color, customColor);
      expect(card.elevation, customElevation);
    });

    testWidgets('renders correctly in aether UI mode (glass)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              const AppModeTheme(
                modeId: 'aether',
                layoutDensity: LayoutDensity.spacious,
                cardStyle: CardStyle.glass,
                assets: ThemeAssetPaths(),
                preferDataTableForLists: false,
                primaryAnimationDuration: Duration(milliseconds: 300),
                listEntranceAnimation: ListEntranceAnimation.fadeSlide,
              ),
            ],
          ),
          home: const Scaffold(body: AppCard(child: Text('Glass'))),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('renders correctly in quantum UI mode (elevated)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              const AppModeTheme(
                modeId: 'quantum',
                layoutDensity: LayoutDensity.compact,
                cardStyle: CardStyle.elevated,
                assets: ThemeAssetPaths(),
                preferDataTableForLists: true,
                primaryAnimationDuration: Duration(milliseconds: 200),
                listEntranceAnimation: ListEntranceAnimation.shimmerSweep,
              ),
            ],
          ),
          home: const Scaffold(body: AppCard(child: Text('Quantum'))),
        ),
      );

      expect(find.byType(BackdropFilter), findsNothing);
      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 2.0);
    });

    testWidgets('renders correctly in elemental UI mode (flat)', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              const AppModeTheme(
                modeId: 'elemental',
                layoutDensity: LayoutDensity.comfortable,
                cardStyle: CardStyle.flat,
                assets: ThemeAssetPaths(),
                preferDataTableForLists: false,
                primaryAnimationDuration: Duration(milliseconds: 300),
                listEntranceAnimation: ListEntranceAnimation.none,
              ),
            ],
          ),
          home: const Scaffold(body: AppCard(child: Text('Elemental'))),
        ),
      );

      final card = tester.widget<Card>(find.byType(Card));
      expect(card.elevation, 0);
    });
  });
}
