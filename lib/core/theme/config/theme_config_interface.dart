// lib/core/theme/config/theme_config_interface.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';

/// Base interface for theme configuration objects.
abstract class IThemePaletteConfig {
  String get paletteIdentifier; // Added identifier
  ColorScheme get lightColorScheme;
  ColorScheme get darkColorScheme;
  ThemeAssetPaths get lightAssets;
  ThemeAssetPaths get darkAssets; // Might often be same as lightAssets
  LayoutDensity get layoutDensity;
  CardStyle get cardStyle;
  Duration get primaryAnimationDuration;
  ListEntranceAnimation get listEntranceAnimation;
  bool get preferDataTableForLists;
  Color? get incomeGlowColorLight; // Specific for brightness
  Color? get expenseGlowColorLight;
  Color? get incomeGlowColorDark;
  Color? get expenseGlowColorDark;
}
