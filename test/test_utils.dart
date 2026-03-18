import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_theme_ext.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

Widget buildTestableWidget(Widget child) {
  return MaterialApp(
    theme: ThemeData.light().copyWith(
      extensions: [
        AppKitTheme(
          colors: AppColors(ThemeData.light().colorScheme),
          typography: AppTypography(ThemeData.light().textTheme),
          spacing: const AppSpacing(),
          radii: const AppRadii(),
          motion: const AppMotion(),
          shadows: AppShadows(isDark: false),
        ),
      ],
    ),
    home: Scaffold(body: child),
  );
}
