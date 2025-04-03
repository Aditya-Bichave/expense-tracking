// lib/core/theme/config/quantum_configs.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For palette identifiers
import 'theme_config_interface.dart'; // Import interface

class QuantumConfig implements IThemePaletteConfig {
  @override
  final ColorScheme lightColorScheme;
  @override
  final ColorScheme darkColorScheme;
  @override
  final ThemeAssetPaths lightAssets;
  @override
  final ThemeAssetPaths darkAssets;
  @override
  final LayoutDensity layoutDensity;
  @override
  final CardStyle cardStyle;
  @override
  final Duration primaryAnimationDuration;
  @override
  final ListEntranceAnimation listEntranceAnimation;
  @override
  final bool preferDataTableForLists;
  // Quantum doesn't use these glow colors
  @override
  final Color? incomeGlowColorLight = null;
  @override
  final Color? expenseGlowColorLight = null;
  @override
  final Color? incomeGlowColorDark = null;
  @override
  final Color? expenseGlowColorDark = null;

  const QuantumConfig({
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.lightAssets,
    required this.darkAssets,
    this.layoutDensity = LayoutDensity.compact,
    this.cardStyle = CardStyle.flat,
    this.primaryAnimationDuration = const Duration(milliseconds: 150),
    this.listEntranceAnimation = ListEntranceAnimation.none,
    this.preferDataTableForLists = true,
  });
}

abstract class QuantumConfigs {
  // Define assets once, reuse for light/dark if they don't change
  static const _commonAssets = ThemeAssetPaths(
    mainBackgroundDark: AppAssets.qBgDark, // Only dark bg defined
    mainBackgroundLight:
        AppAssets.qBgDark, // Use dark for light mode too? Or define a light one
    cardBackground: AppAssets.qBgCardDark,
    divider: null, // No SVG divider
    focusRing: null, // No SVG focus ring
    commonIcons: {
      AppModeTheme.iconAdd: AppAssets.qComIconAdd,
      AppModeTheme.iconSettings: AppAssets.qComIconSettings,
      AppModeTheme.iconBack: AppAssets.qComIconBack,
      AppModeTheme.iconCalendar: AppAssets.qComIconCalendar,
      AppModeTheme.iconCategory: AppAssets.qComIconCategory,
      AppModeTheme.iconChart: AppAssets.qComIconChart,
      AppModeTheme.iconDelete: AppAssets.qComIconDelete,
      AppModeTheme.iconMenu: AppAssets.qComIconMenu,
      AppModeTheme.iconExpense: AppAssets.qComIconExpense,
      AppModeTheme.iconIncome: AppAssets.qComIconIncome,
      AppModeTheme.iconUndo: AppAssets.qComIconUndo,
      AppModeTheme.iconNotes: AppAssets.qComIconCategory, // Fallback
      AppModeTheme.iconTheme: AppAssets.qComIconSettings, // Fallback
      AppModeTheme.iconWallet: AppAssets.qComIconCategory, // Fallback
    },
    categoryIcons: {
      'groceries': AppAssets.qCatIconGroceries,
      'rent': AppAssets.qCatIconRent,
      'utilities': AppAssets.qCatIconUtilities,
      'freelance': AppAssets.qCatIconFreelance,
      'food': AppAssets.qCatIconGroceries, // Reuse
      'transport': AppAssets.qComIconExpense, // Fallback
      'entertainment': AppAssets.qComIconExpense, // Fallback
      'medical': AppAssets.qComIconExpense, // Fallback
      'salary': AppAssets.qComIconIncome, // Fallback
      'subscription': AppAssets.qCatIconUtilities, // Reuse
      'housing': AppAssets.qCatIconRent, // Reuse
      'bonus': AppAssets.qComIconIncome, // Fallback
      'gift': AppAssets.qComIconIncome, // Fallback
      'interest': AppAssets.qComIconIncome, // Fallback
      'other': AppAssets.qComIconCategory, // Fallback
      'bank': AppAssets.qComIconCategory, // Fallback
      'cash': AppAssets.qComIconCategory, // Fallback
      'crypto': AppAssets.qComIconCategory, // Fallback
      'investment': AppAssets.qComIconChart, // Fallback
    },
    illustrations: {
      'empty_transactions': AppAssets.qIlluEmptyTransactions,
      'empty_dark_sky': AppAssets.qIlluEmptyDarkSky,
      'empty_add_first': AppAssets.qIlluEmptyAddFirst,
      'empty_filter': AppAssets.qIlluEmptyTransactions, // Reuse
    },
    charts: {
      'bar_generic': AppAssets.qChartBarTemplate,
      'progress_income': AppAssets.qChartProgressIncome,
      'progress_expense': AppAssets.qChartProgressExpense,
      'pie_category': AppAssets.qChartPieCategory,
      'stat_widget_frame': AppAssets.qChartStatWidgetFrame,
    },
  );

  // Specific assets for each palette (mainly FAB glow)
  static final _p1Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.qP1FabGlow);
  static final _p2Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.qP2FabGlow);
  static final _p3Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.qP3FabGlow);
  static final _p4Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.qP4FabGlow);

  static final Map<String, QuantumConfig> palettes = {
    AppTheme.quantumPalette1: QuantumConfig(
      lightColorScheme: const ColorScheme.light(
          primary: Color(0xFF00838F),
          secondary: Color(0xFF00ACC1),
          tertiary: Color(0xFF00A74E),
          background: Color(0xFFFAFAFA),
          surface: Color(0xFFFFFFFF),
          surfaceContainer: Color(0xFFF5F5F5),
          error: Color(0xFFD32F2F),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF666666),
          onError: Colors.white,
          outline: Color(0xFFBDBDBD),
          outlineVariant: Color(0xFFCCCCCC),
          primaryContainer: Color(0xFFB2EBF2),
          onPrimaryContainer: Color(0xFF006064),
          brightness: Brightness.light),
      darkColorScheme: const ColorScheme.dark(
          primary: Color(0xFF00BCD4),
          secondary: Color(0xFF80DEEA),
          tertiary: Color(0xFF00E676),
          background: Color(0xFF121212),
          surface: Color(0xFF1E1E1E),
          surfaceContainer: Color(0xFF242424),
          error: Color(0xFFFF5252),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFAAAAAA),
          onError: Colors.black,
          outline: Color(0xFF444444),
          outlineVariant: Color(0xFF333333),
          primaryContainer: Color(0xFF005662),
          onPrimaryContainer: Color(0xFF80DEEA),
          brightness: Brightness.dark),
      lightAssets: _p1Assets,
      darkAssets: _p1Assets,
    ),
    AppTheme.quantumPalette2: QuantumConfig(
      lightColorScheme: const ColorScheme.light(
          primary: Color(0xFF304FFE),
          secondary: Color(0xFF448AFF),
          tertiary: Color(0xFF00A74E),
          background: Color(0xFFF0F4F8),
          surface: Color(0xFFFFFFFF),
          surfaceContainer: Color(0xFFE3F2FD),
          error: Color(0xFFF50057),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF607D8B),
          onError: Colors.white,
          outline: Color(0xFFB0BEC5),
          outlineVariant: Color(0xFFCFD8DC),
          primaryContainer: Color(0xFFC5CAE9),
          onPrimaryContainer: Color(0xFF1A237E),
          brightness: Brightness.light),
      darkColorScheme: const ColorScheme.dark(
          primary: Color(0xFF3D5AFE),
          secondary: Color(0xFF90CAF9),
          tertiary: Color(0xFF00E676),
          background: Color(0xFF0F1C2E),
          surface: Color(0xFF1E2D3C),
          surfaceContainer: Color(0xFF283A4C),
          error: Color(0xFFFF4081),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFB0BEC5),
          onError: Colors.black,
          outline: Color(0xFF445A70),
          outlineVariant: Color(0xFF334659),
          primaryContainer: Color(0xFF1A237E),
          onPrimaryContainer: Color(0xFFC5CAE9),
          brightness: Brightness.dark),
      lightAssets: _p2Assets,
      darkAssets: _p2Assets,
    ),
    AppTheme.quantumPalette3: QuantumConfig(
      lightColorScheme: const ColorScheme.light(
          primary: Color(0xFFD32F2F),
          secondary: Color(0xFFE57373),
          tertiary: Color(0xFF4CAF50),
          background: Color(0xFFFFF8F8),
          surface: Color(0xFFFFFFFF),
          surfaceContainer: Color(0xFFFFEBEE),
          error: Color(0xFFC62828),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF757575),
          onError: Colors.white,
          outline: Color(0xFFE0E0E0),
          outlineVariant: Color(0xFFF5F5F5),
          primaryContainer: Color(0xFFFFCDD2),
          onPrimaryContainer: Color(0xFFB71C1C),
          brightness: Brightness.light),
      darkColorScheme: const ColorScheme.dark(
          primary: Color(0xFFEF5350),
          secondary: Color(0xFFFF8A80),
          tertiary: Color(0xFF66BB6A),
          background: Color(0xFF1A0000),
          surface: Color(0xFF330000),
          surfaceContainer: Color(0xFF4D0000),
          error: Color(0xFFFF1744),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.white,
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFEF9A9A),
          onError: Colors.white,
          outline: Color(0xFF663333),
          outlineVariant: Color(0xFF552222),
          primaryContainer: Color(0xFFB71C1C),
          onPrimaryContainer: Color(0xFFFFCDD2),
          brightness: Brightness.dark),
      lightAssets: _p3Assets,
      darkAssets: _p3Assets,
    ),
    AppTheme.quantumPalette4: QuantumConfig(
      lightColorScheme: const ColorScheme.light(
          primary: Color(0xFF5C6BC0),
          secondary: Color(0xFF7986CB),
          tertiary: Color(0xFF66BB6A),
          background: Color(0xFFF1F3F4),
          surface: Color(0xFFFFFFFF),
          surfaceContainer: Color(0xFFE8EAED),
          error: Color(0xFFE53935),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF5F6368),
          onError: Colors.white,
          outline: Color(0xFFDADCE0),
          outlineVariant: Color(0xFFE8EAED),
          primaryContainer: Color(0xFFC5CAE9),
          onPrimaryContainer: Color(0xFF3F51B5),
          brightness: Brightness.light),
      darkColorScheme: const ColorScheme.dark(
          primary: Color(0xFF9FA8DA),
          secondary: Color(0xFFC5CAE9),
          tertiary: Color(0xFF81C784),
          background: Color(0xFF202124),
          surface: Color(0xFF2A2B2E),
          surfaceContainer: Color(0xFF333438),
          error: Color(0xFFE57373),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Color(0xFFE8EAED),
          onSurface: Color(0xFFE8EAED),
          onSurfaceVariant: Color(0xFFB0BEC5),
          onError: Colors.black,
          outline: Color(0xFF5F6368),
          outlineVariant: Color(0xFF4A4B4F),
          primaryContainer: Color(0xFF3F51B5),
          onPrimaryContainer: Color(0xFFC5CAE9),
          brightness: Brightness.dark),
      lightAssets: _p4Assets,
      darkAssets: _p4Assets,
    ),
  };

  static IThemePaletteConfig getConfig(String paletteIdentifier) {
    return palettes[paletteIdentifier] ??
        palettes[AppTheme.quantumPalette1]!; // Fallback
  }
}
