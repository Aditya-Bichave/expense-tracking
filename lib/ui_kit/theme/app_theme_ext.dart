import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';

@immutable
class AppKitTheme extends ThemeExtension<AppKitTheme> {
  final AppColors colors;
  final AppTypography typography;
  final AppSpacing spacing;
  final AppRadii radii;
  final AppMotion motion;

  const AppKitTheme({
    required this.colors,
    required this.typography,
    required this.spacing,
    required this.radii,
    required this.motion,
  });

  @override
  AppKitTheme copyWith({
    AppColors? colors,
    AppTypography? typography,
    AppSpacing? spacing,
    AppRadii? radii,
    AppMotion? motion,
  }) {
    return AppKitTheme(
      colors: colors ?? this.colors,
      typography: typography ?? this.typography,
      spacing: spacing ?? this.spacing,
      radii: radii ?? this.radii,
      motion: motion ?? this.motion,
    );
  }

  @override
  AppKitTheme lerp(ThemeExtension<AppKitTheme>? other, double t) {
    if (other is! AppKitTheme) {
      return this;
    }
    // Note: Most tokens are not lerpable or don't need to be (like spacing constants).
    // Colors and Typography are implicitly handled by Theme.of(context) usually,
    // but here we are wrapping them. Since they wrap the *active* scheme,
    // they should be updated by the theme engine.
    // However, if we change modes, we might want to lerp some values.
    // For now, we return 'other' if t > 0.5 to switch effectively.
    // A proper implementation would lerp individual properties if they were dynamic.
    return t < 0.5 ? this : other;
  }
}

extension AppKitThemeContextExtension on BuildContext {
  AppKitTheme get kit {
    final theme = Theme.of(this).extension<AppKitTheme>();
    if (theme == null) {
      // Fallback if extension is missing (should not happen if set up correctly)
      // This allows 'hot' usages even if theme isn't fully rebuilt yet during dev
      final colorScheme = Theme.of(this).colorScheme;
      final textTheme = Theme.of(this).textTheme;
      return AppKitTheme(
        colors: AppColors(colorScheme),
        typography: AppTypography(textTheme),
        spacing: const AppSpacing(),
        radii: const AppRadii(),
        motion: const AppMotion(),
      );
    }
    return theme;
  }
}
