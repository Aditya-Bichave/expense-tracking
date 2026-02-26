import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

@immutable
class AppKitTheme extends ThemeExtension<AppKitTheme> {
  final AppColors colors;
  final AppTypography typography;
  final AppSpacing spacing;
  final AppRadii radii;
  final AppMotion motion;
  final AppShadows shadows;

  const AppKitTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.motion,
    required this.shadows,
  });

  @override
  AppKitTheme copyWith({
    AppColors? colors,
    AppTypography? typography,
    AppSpacing? spacing,
    AppRadii? radii,
    AppMotion? motion,
    AppShadows? shadows,
  }) {
    return AppKitTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      motion: motion ?? this.motion,
      shadows: shadows ?? this.shadows,
    );
  }

  @override
  AppKitTheme lerp(ThemeExtension<AppKitTheme>? other, double t) {
    if (other is! AppKitTheme) {
      return this;
    }
    // Most tokens are constants or wrappers around scheme, so simple switching is safer/cleaner.
    // If dynamic lerping is needed, implement individually.
    return t < 0.5 ? this : other;
  }
}

extension AppKitThemeContextExtension on BuildContext {
  AppKitTheme get kit {
    final theme = Theme.of(this).extension<AppKitTheme>();
    if (theme == null) {
      // Fallback if extension is missing (should not happen if set up correctly)
      final colorScheme = Theme.of(this).colorScheme;
      final textTheme = Theme.of(this).textTheme;
      final isDark = Theme.of(this).brightness == Brightness.dark;

      return AppKitTheme(
        colors: AppColors(colorScheme),
        typography: AppTypography(textTheme),
        spacing: const AppSpacing(),
        radii: const AppRadii(),
        motion: const AppMotion(),
        shadows: AppShadows(isDark: isDark),
      );
    }
    return theme;
  }
}
