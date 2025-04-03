// lib/core/theme/config/aether_configs.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For palette identifiers
import 'theme_config_interface.dart'; // Import interface

class AetherConfig implements IThemePaletteConfig {
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
  @override
  final Color? incomeGlowColorLight;
  @override
  final Color? expenseGlowColorLight;
  @override
  final Color? incomeGlowColorDark;
  @override
  final Color? expenseGlowColorDark;

  const AetherConfig({
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.lightAssets,
    required this.darkAssets,
    this.layoutDensity = LayoutDensity.spacious,
    this.cardStyle = CardStyle.floating,
    this.primaryAnimationDuration = const Duration(milliseconds: 450),
    this.listEntranceAnimation = ListEntranceAnimation.shimmerSweep,
    this.preferDataTableForLists = false,
    required this.incomeGlowColorLight,
    required this.expenseGlowColorLight,
    required this.incomeGlowColorDark,
    required this.expenseGlowColorDark,
  });
}

abstract class AetherConfigs {
  // Common icons for Aether mode
  static const Map<String, String> _commonIcons = {
    AppModeTheme.iconAdd: AppAssets.aeComIconAdd,
    AppModeTheme.iconSettings: AppAssets.aeComIconSettings,
    AppModeTheme.iconCalendar: AppAssets.aeComIconCalendar,
    AppModeTheme.iconCategory: AppAssets.aeComIconCategory,
    AppModeTheme.iconNotes: AppAssets.aeComIconNotes,
    AppModeTheme.iconTheme: AppAssets.aeComIconTheme,
    AppModeTheme.iconSync: AppAssets.aeComIconSync,
    AppModeTheme.iconPrivacy: AppAssets.aeComIconPrivacy,
    AppModeTheme.iconBooks: AppAssets.aeComIconBooks,
    AppModeTheme.iconRestaurant: AppAssets.aeComIconRestaurant,
    AppModeTheme.iconSalary: AppAssets.aeComIconSalary,
    // Define other common ones if needed
  };

  // Common illustrations and charts for Aether
  static const _commonIllustrations = {
    'empty_transactions': AppAssets.aeIlluEmptyStarscape,
    'add_first': AppAssets.aeIlluAddFirstTransaction,
    'planet_island': AppAssets.aeIlluPlanetIsland,
    'empty_filter': AppAssets.aeIlluEmptyStarscape,
  };
  static const _commonCharts = {
    'balance_indicator': AppAssets.aeChartBalanceCircle,
    'weekly_sparkline': AppAssets.aeChartWeeklySparkline,
    'top_cat_income': AppAssets.aeChartTopCatIncome,
    'top_cat_food': AppAssets.aeChartTopCatFood,
    'top_cat_bills': AppAssets.aeChartTopCatBills,
    'top_cat_entertainment': AppAssets.aeChartTopCatEntertainment,
  };

  // --- Palette 1: Starfield ---
  static const _p1Assets = ThemeAssetPaths(
    mainBackgroundDark: AppAssets.aeBgStarfield,
    mainBackgroundLight:
        AppAssets.aeBgStarfield, // Same background for light/dark
    fabGlow: AppAssets.aeP1FabGlow,
    commonIcons: _commonIcons,
    categoryIcons: {
      // Specific overrides + fallbacks
      'groceries': AppAssets.aeP1IconGroceries,
      'salary': AppAssets.aeComIconSalary,
      // ... add other category overrides or rely on common aether map
      'other': AppAssets.aeComIconCategory,
    },
    illustrations: _commonIllustrations,
    charts: {
      ..._commonCharts, // Include common charts
      'income_node': AppAssets.aeP1PlanetIncome,
      'expense_node': AppAssets.aeP1PlanetExpense,
      'balance_node': AppAssets.aeP1StarsOverlay,
    },
  );

  // --- Palette 2: Garden ---
  static const _p2Assets = ThemeAssetPaths(
    mainBackgroundDark: AppAssets.aeBgGarden,
    mainBackgroundLight: AppAssets.aeBgGarden,
    fabGlow: AppAssets.aeP2FabGlow,
    commonIcons: _commonIcons,
    categoryIcons: {
      'groceries': AppAssets.aeP2IconGroceries,
      'salary': AppAssets.aeComIconSalary,
      'other': AppAssets.aeComIconCategory,
    },
    illustrations: _commonIllustrations,
    charts: {
      ..._commonCharts,
      'income_node': AppAssets.aeP2ButterflyIncome,
      'expense_node': AppAssets.aeP2TreeExpense,
      'balance_node': AppAssets.aeP2LeafBalance,
    },
  );

  // --- Palette 3: Mystic ---
  static const _p3Assets = ThemeAssetPaths(
    mainBackgroundDark: AppAssets.aeBgMystic,
    mainBackgroundLight: AppAssets.aeBgMystic,
    fabGlow: AppAssets.aeP3FabGlow,
    commonIcons: _commonIcons,
    categoryIcons: {
      'groceries': AppAssets.aeP3IconGroceries,
      'salary': AppAssets.aeComIconSalary,
      'other': AppAssets.aeComIconCategory,
    },
    illustrations: _commonIllustrations,
    charts: {
      ..._commonCharts,
      'income_node': AppAssets.aeP3MysticEyeIncome,
      'expense_node': AppAssets.aeP3WandExpense,
      'balance_node': AppAssets.aeP3OrbBalance,
    },
  );

  // --- Palette 4: Calm Sky ---
  static const _p4Assets = ThemeAssetPaths(
    mainBackgroundDark: AppAssets.aeBgCalm,
    mainBackgroundLight: AppAssets.aeBgCalm,
    fabGlow: AppAssets.aeP4FabGlow,
    commonIcons: _commonIcons,
    categoryIcons: {
      'groceries': AppAssets.aeP4IconGroceries,
      'salary': AppAssets.aeComIconSalary,
      'other': AppAssets.aeComIconCategory,
    },
    illustrations: _commonIllustrations,
    charts: {
      ..._commonCharts,
      'income_node': AppAssets.aeP4CloudIncome,
      'expense_node': AppAssets.aeP4RainExpense,
      'balance_node': AppAssets.aeP4MoonBalance,
    },
  );

  static final Map<String, AetherConfig> palettes = {
    AppTheme.aetherPalette1: const AetherConfig(
      lightColorScheme: ColorScheme.light(
          primary: Color(0xFF7C4DFF),
          secondary: Color(0xFF9575CD),
          tertiary: Color(0xFF00BFA5),
          background: Color(0xFFE8EAF6),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF0F0F8),
          error: Color(0xFFEF5350),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF7986CB),
          onError: Colors.white,
          primaryContainer: Color(0xFFD1C4E9),
          onPrimaryContainer: Color(0xFF512DA8),
          tertiaryContainer: Color(0xFF78FFE1),
          onTertiaryContainer: Color(0xFF003D31),
          brightness: Brightness.light),
      darkColorScheme: ColorScheme.dark(
          primary: Color(0xFFA18BFF),
          secondary: Color(0xFFB39DDB),
          tertiary: Color(0xFF00FFAA),
          background: Color(0xFF0F0D2E),
          surface: Color(0xFF1C183F),
          surfaceVariant: Color(0xFF2A2450),
          error: Color(0xFFFF6B81),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Color(0xFFCCCCDD),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xAA9999AA),
          onError: Colors.black,
          primaryContainer: Color(0xFF512DA8),
          onPrimaryContainer: Color(0xFFD1C4E9),
          tertiaryContainer: Color(0xFF00503B),
          onTertiaryContainer: Color(0xFF50FFC1),
          brightness: Brightness.dark),
      lightAssets: _p1Assets,
      darkAssets: _p1Assets, // Aether assets often same for light/dark
      incomeGlowColorLight: Color(0xAA00BFA5),
      expenseGlowColorLight: Color(0xAAEF5350),
      incomeGlowColorDark: Color(0xAA00FFAA),
      expenseGlowColorDark: Color(0xAAFF6B81),
    ),
    AppTheme.aetherPalette2: const AetherConfig(
      lightColorScheme: ColorScheme.light(
          primary: Color(0xFF00BFA5),
          secondary: Color(0xFF69F0AE),
          tertiary: Color(0xFFFFAB40),
          background: Color(0xFFE8F5E9),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF0FAF1),
          error: Color(0xFFFF6E40),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF4CAF50),
          onError: Colors.black,
          primaryContainer: Color(0xFFA7FFEB),
          onPrimaryContainer: Color(0xFF00695C),
          tertiaryContainer: Color(0xFFFFD180),
          onTertiaryContainer: Color(0xFF5F4000),
          brightness: Brightness.light),
      darkColorScheme: ColorScheme.dark(
          primary: Color(0xFF88FFC2),
          secondary: Color(0xFFA5D6A7),
          tertiary: Color(0xFFFFD180),
          background: Color(0xFF101F1C),
          surface: Color(0xFF1B2C27),
          surfaceVariant: Color(0xFF2C3E39),
          error: Color(0xFFFF7043),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Color(0xFFFAFAFA),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFA5D6A7),
          onError: Colors.black,
          primaryContainer: Color(0xFF00695C),
          onPrimaryContainer: Color(0xFFA7FFEB),
          tertiaryContainer: Color(0xFF5F4000),
          onTertiaryContainer: Color(0xFFFFE082),
          brightness: Brightness.dark),
      lightAssets: _p2Assets,
      darkAssets: _p2Assets,
      incomeGlowColorLight: Color(0xAA00BFA5),
      expenseGlowColorLight: Color(0xAAFF6E40),
      incomeGlowColorDark: Color(0xAA88FFC2),
      expenseGlowColorDark: Color(0xAAFF7043),
    ),
    AppTheme.aetherPalette3: const AetherConfig(
      lightColorScheme: ColorScheme.light(
          primary: Color(0xFFAB47BC),
          secondary: Color(0xFFCE93D8),
          tertiary: Color(0xFF00BFA5),
          background: Color(0xFFF3E5F5),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF8F0FC),
          error: Color(0xFFDD2C00),
          onPrimary: Colors.white,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF8E24AA),
          onError: Colors.white,
          primaryContainer: Color(0xFFE1BEE7),
          onPrimaryContainer: Color(0xFF6A1B9A),
          tertiaryContainer: Color(0xFF00E676),
          onTertiaryContainer: Color(0xFF003E20),
          brightness: Brightness.light),
      darkColorScheme: ColorScheme.dark(
          primary: Color(0xFFD0B3FF),
          secondary: Color(0xFFE1BEE7),
          tertiary: Color(0xFF00E676),
          background: Color(0xFF1B0033),
          surface: Color(0xFF29004D),
          surfaceVariant: Color(0xFF3C006A),
          error: Color(0xFFFF3D00),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Color(0xFFF3E5F5),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFFCE93D8),
          onError: Colors.white,
          primaryContainer: Color(0xFF6A1B9A),
          onPrimaryContainer: Color(0xFFE1BEE7),
          tertiaryContainer: Color(0xFF005129),
          onTertiaryContainer: Color(0xFF3EFF99),
          brightness: Brightness.dark),
      lightAssets: _p3Assets,
      darkAssets: _p3Assets,
      incomeGlowColorLight: Color(0xAA00BFA5),
      expenseGlowColorLight: Color(0xAADD2C00),
      incomeGlowColorDark: Color(0xAA00E676),
      expenseGlowColorDark: Color(0xAAFF3D00),
    ),
    AppTheme.aetherPalette4: const AetherConfig(
      lightColorScheme: ColorScheme.light(
          primary: Color(0xFF4FC3F7),
          secondary: Color(0xFF81D4FA),
          tertiary: Color(0xFF26A69A),
          background: Color(0xFFE3F2FD),
          surface: Color(0xFFFFFFFF),
          surfaceVariant: Color(0xFFF0F7FC),
          error: Color(0xFFE57373),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Colors.black,
          onSurface: Colors.black,
          onSurfaceVariant: Color(0xFF546E7A),
          onError: Colors.white,
          primaryContainer: Color(0xFFB3E5FC),
          onPrimaryContainer: Color(0xFF0277BD),
          tertiaryContainer: Color(0xFF78F8D6),
          onTertiaryContainer: Color(0xFF00382A),
          brightness: Brightness.light),
      darkColorScheme: ColorScheme.dark(
          primary: Color(0xFF89CFF0),
          secondary: Color(0xFFB0E0E6),
          tertiary: Color(0xFF00DFA2),
          background: Color(0xFF121F2E),
          surface: Color(0xFF1C2E45),
          surfaceVariant: Color(0xFF2C3E50),
          error: Color(0xFFF08080),
          onPrimary: Colors.black,
          onSecondary: Colors.black,
          onBackground: Color(0xFFECEFF1),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xFF90A4AE),
          onError: Colors.black,
          primaryContainer: Color(0xFF0277BD),
          onPrimaryContainer: Color(0xFFB3E5FC),
          tertiaryContainer: Color(0xFF00513B),
          onTertiaryContainer: Color(0xFF34FFC1),
          brightness: Brightness.dark),
      lightAssets: _p4Assets,
      darkAssets: _p4Assets,
      incomeGlowColorLight: Color(0xAA26A69A),
      expenseGlowColorLight: Color(0xAAE57373),
      incomeGlowColorDark: Color(0xAA00DFA2),
      expenseGlowColorDark: Color(0xAAF08080),
    ),
  };

  static IThemePaletteConfig getConfig(String paletteIdentifier) {
    return palettes[paletteIdentifier] ??
        palettes[AppTheme.aetherPalette1]!; // Fallback
  }
}
