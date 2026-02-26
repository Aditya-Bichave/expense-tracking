import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// UI Kit
import 'package:expense_tracker/ui_kit/components/buttons/app_button.dart';
import 'package:expense_tracker/ui_kit/components/foundations/app_card.dart';
import 'package:expense_tracker/ui_kit/components/inputs/app_text_field.dart';
import 'package:expense_tracker/ui_kit/components/lists/app_list_tile.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';

// Bridge
import 'package:expense_tracker/ui_bridge/ui_bridge.dart';

void main() {
  group('UI Kit Smoke Test', () {
    testWidgets('AppKitTheme extension is available in context', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AppKitTheme(
                colors: AppColors(ColorScheme.fromSeed(seedColor: Colors.blue)),
                typography: AppTypography(
                  Typography.material2021().englishLike,
                ),
                spacing: const AppSpacing(),
                radii: const AppRadii(),
                motion: const AppMotion(),
                shadows: const AppShadows(),
              ),
            ],
          ),
          home: Builder(
            builder: (context) {
              final kit = context.kit;
              expect(kit, isNotNull);
              return const SizedBox();
            },
          ),
        ),
      );
    });

    testWidgets('UiKit components instantiate correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AppKitTheme(
                colors: AppColors(ColorScheme.fromSeed(seedColor: Colors.blue)),
                typography: AppTypography(
                  Typography.material2021().englishLike,
                ),
                spacing: const AppSpacing(),
                radii: const AppRadii(),
                motion: const AppMotion(),
                shadows: const AppShadows(),
              ),
            ],
          ),
          home: Scaffold(
            body: Column(
              children: [
                AppButton(
                  label: 'Primary',
                  onPressed: () {},
                  variant: UiVariant.primary,
                ),
                AppButton(label: 'Disabled', onPressed: () {}, disabled: true),
                AppButton(label: 'Loading', onPressed: () {}, isLoading: true),
                const AppCard(child: Text('Card Content')),
                const AppTextField(label: 'Input'),
                const AppListTile(title: Text('List Tile')),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Disabled'), findsOneWidget);
      expect(find.text('Loading'), findsOneWidget);
      expect(find.text('Card Content'), findsOneWidget);
      expect(find.text('Input'), findsOneWidget);
      expect(find.text('List Tile'), findsOneWidget);
    });

    testWidgets('Bridge components instantiate correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: [
              AppKitTheme(
                colors: AppColors(ColorScheme.fromSeed(seedColor: Colors.blue)),
                typography: AppTypography(
                  Typography.material2021().englishLike,
                ),
                spacing: const AppSpacing(),
                radii: const AppRadii(),
                motion: const AppMotion(),
                shadows: const AppShadows(),
              ),
            ],
          ),
          home: Scaffold(
            body: Column(
              children: [
                BridgeButton(label: 'Bridge Primary', onPressed: () {}),
                BridgeButton.secondary(
                  label: 'Bridge Secondary',
                  onPressed: () {},
                ),
                const BridgeCard(child: Text('Bridge Card')),
                const BridgeTextField(label: 'Bridge Input'),
                const BridgeListTile(title: Text('Bridge Tile')),
                const BridgeText('Bridge Text'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bridge Primary'), findsOneWidget);
      expect(find.text('Bridge Secondary'), findsOneWidget);
      expect(find.text('Bridge Card'), findsOneWidget);
      expect(find.text('Bridge Input'), findsOneWidget);
      expect(find.text('Bridge Tile'), findsOneWidget);
      expect(find.text('Bridge Text'), findsOneWidget);
    });
  });
}
