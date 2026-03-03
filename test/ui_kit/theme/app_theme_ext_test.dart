import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

void main() {
  group('AppKitTheme', () {
    final defaultTheme = AppKitTheme(
      colors: AppColors(ColorScheme.light()),
      typography: AppTypography(TextTheme()),
      spacing: const AppSpacing(),
      radii: const AppRadii(),
      motion: const AppMotion(),
      shadows: AppShadows(isDark: false),
    );

    test('copyWith updates properties', () {
      final newColors = AppColors(ColorScheme.dark());
      final updatedTheme = defaultTheme.copyWith(colors: newColors);

      expect(updatedTheme.colors, newColors);
      expect(updatedTheme.typography, defaultTheme.typography);
    });

    test('lerp works correctly', () {
      final newTheme = AppKitTheme(
        colors: AppColors(ColorScheme.dark()),
        typography: AppTypography(TextTheme()),
        spacing: const AppSpacing(),
        radii: const AppRadii(),
        motion: const AppMotion(),
        shadows: AppShadows(isDark: true),
      );

      final lerpedHalf = defaultTheme.lerp(newTheme, 0.4);
      expect(lerpedHalf.colors, defaultTheme.colors);

      final lerpedFull = defaultTheme.lerp(newTheme, 0.6);
      expect(lerpedFull.colors, newTheme.colors);

      final lerpedOther = defaultTheme.lerp(null, 0.5);
      expect(lerpedOther, defaultTheme);
    });
  });

  group('AppKitThemeContextExtension', () {
    testWidgets('kit returns provided extension', (tester) async {
      final theme = AppKitTheme(
        colors: AppColors(ColorScheme.light()),
        typography: AppTypography(TextTheme()),
        spacing: const AppSpacing(),
        radii: const AppRadii(),
        motion: const AppMotion(),
        shadows: AppShadows(isDark: false),
      );

      AppKitTheme? contextTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData().copyWith(extensions: [theme]),
          home: Builder(
            builder: (context) {
              contextTheme = context.kit;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(contextTheme, theme);
    });

    testWidgets('kit returns fallback when extension is missing', (
      tester,
    ) async {
      AppKitTheme? contextTheme;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(),
          home: Builder(
            builder: (context) {
              contextTheme = context.kit;
              return const SizedBox();
            },
          ),
        ),
      );

      expect(contextTheme, isNotNull);
      expect(contextTheme!.spacing, isA<AppSpacing>());
    });
  });
}
