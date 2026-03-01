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
                BridgeButton.primary(
                  label: 'Bridge Primary Named',
                  onPressed: () {},
                ),
                BridgeButton.secondary(
                  label: 'Bridge Secondary',
                  onPressed: () {},
                ),
                BridgeButton.ghost(label: 'Bridge Ghost', onPressed: () {}),
                BridgeButton.destructive(
                  label: 'Bridge Destructive',
                  onPressed: () {},
                ),
                const BridgeCard(child: Text('Bridge Card')),
                const BridgeTextField(label: 'Bridge Input'),
                const BridgeListTile(title: Text('Bridge Tile')),
                const BridgeText('Bridge Text'),
                const BridgeLoadingIndicator(),
                const BridgeSkeleton(),
                const BridgeEmptyState(title: 'Empty'),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Bridge Primary'), findsOneWidget);
      expect(find.text('Bridge Primary Named'), findsOneWidget);
      expect(find.text('Bridge Secondary'), findsOneWidget);
      expect(find.text('Bridge Ghost'), findsOneWidget);
      expect(find.text('Bridge Destructive'), findsOneWidget);
      expect(find.text('Bridge Card'), findsOneWidget);
      expect(find.text('Bridge Input'), findsOneWidget);
      expect(find.text('Bridge Tile'), findsOneWidget);
      expect(find.text('Bridge Text'), findsOneWidget);
      expect(find.text('Empty'), findsOneWidget);
    });

    testWidgets('AppButton renders all variants correctly', (tester) async {
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
                  variant: UiVariant.primary,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Secondary',
                  variant: UiVariant.secondary,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Ghost',
                  variant: UiVariant.ghost,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Destructive',
                  variant: UiVariant.destructive,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Destructive Secondary',
                  variant: UiVariant.destructiveSecondary,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Success',
                  variant: UiVariant.success,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Small',
                  size: AppButtonSize.small,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Large',
                  size: AppButtonSize.large,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'Full Width',
                  isFullWidth: true,
                  onPressed: () {},
                ),
                AppButton(
                  label: 'With Icon',
                  icon: const Icon(Icons.add),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('Primary'), findsOneWidget);
      expect(find.text('Secondary'), findsOneWidget);
      expect(find.text('Ghost'), findsOneWidget);
      expect(find.text('Destructive'), findsOneWidget);
      expect(find.text('Destructive Secondary'), findsOneWidget);
      // Falls back to default in switch
      expect(find.text('Success'), findsOneWidget);
      expect(find.text('Small'), findsOneWidget);
      expect(find.text('Large'), findsOneWidget);
      expect(find.text('Full Width'), findsOneWidget);
      expect(find.text('With Icon'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });

    test('AppKitTheme copyWith and lerp', () {
      final theme1 = AppKitTheme(
        colors: AppColors(ColorScheme.fromSeed(seedColor: Colors.blue)),
        typography: AppTypography(Typography.material2021().englishLike),
        spacing: const AppSpacing(),
        radii: const AppRadii(),
        motion: const AppMotion(),
        shadows: const AppShadows(),
      );

      final theme2 = theme1.copyWith();
      expect(theme2, isNotNull);

      final theme3 = theme1.lerp(theme1, 0.5);
      expect(theme3, isNotNull);

      final theme4 = theme1.lerp(null, 0.5);
      expect(theme4, theme1);
    });

    testWidgets('BridgeDialog shows dialog', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BridgeDialog.showAlert(
                    context: context,
                    title: 'Alert',
                    content: 'Content',
                  );
                },
                child: const Text('Show Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Alert'), findsOneWidget);
      expect(find.text('Content'), findsOneWidget);
    });

    testWidgets('BridgeBottomSheet shows sheet', (tester) async {
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
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BridgeBottomSheet.show(
                    context: context,
                    title: 'Sheet',
                    child: const Text('Sheet Content'),
                  );
                },
                child: const Text('Show Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet'), findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);
    });
  });
}
