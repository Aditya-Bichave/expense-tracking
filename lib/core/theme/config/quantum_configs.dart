import 'package:flutter/material.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For palette identifiers
import 'theme_config_interface.dart'; // Import interface

// Config class implements the interface
class QuantumConfig implements IThemePaletteConfig {
  @override
  final String paletteIdentifier;
  @override
  final ColorScheme lightColorScheme;
  @override
  final ColorScheme darkColorScheme;
  @override
  final ThemeAssetPaths lightAssets;
  @override
  final ThemeAssetPaths darkAssets;
  // Quantum Specific Defaults
  @override
  final LayoutDensity layoutDensity = LayoutDensity.compact;
  @override
  final CardStyle cardStyle = CardStyle.flat;
  @override
  final Duration primaryAnimationDuration = const Duration(milliseconds: 150);
  @override
  final ListEntranceAnimation listEntranceAnimation =
      ListEntranceAnimation.none;
  @override
  final bool preferDataTableForLists = true;
  // Quantum doesn't use glow colors
  @override
  final Color? incomeGlowColorLight = null;
  @override
  final Color? expenseGlowColorLight = null;
  @override
  final Color? incomeGlowColorDark = null;
  @override
  final Color? expenseGlowColorDark = null;
  // Quantum specific overrides for new properties (optional)
  final EdgeInsets? cardOuterPadding = const EdgeInsets.symmetric(
    horizontal: 8.0,
    vertical: 4.0,
  );
  final EdgeInsets? listItemPadding = const EdgeInsets.symmetric(
    horizontal: 12.0,
    vertical: 2.0,
  );
  final Duration? mediumDuration = const Duration(milliseconds: 150);
  final Duration? fastDuration = const Duration(milliseconds: 100);

  const QuantumConfig({
    required this.paletteIdentifier,
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.lightAssets,
    required this.darkAssets,
    // Allow overriding defaults if needed
    // this.layoutDensity = LayoutDensity.compact,
    // etc.
  });
}

abstract class QuantumConfigs {
  // Base assets definition using AssetKeys
  static const _baseAssets = ThemeAssetPaths(
    mainBackgroundDark: AppAssets.qBgDark,
    mainBackgroundLight: AppAssets.qBgDark,
    cardBackground: AppAssets.qBgCardDark,
    divider: null,
    focusRing: null,
    commonIcons: {
      AssetKeys.iconAdd: AppAssets.qComIconAdd,
      AssetKeys.iconSettings: AppAssets.qComIconSettings,
      AssetKeys.iconBack: AppAssets.qComIconBack,
      AssetKeys.iconCalendar: AppAssets.qComIconCalendar,
      AssetKeys.iconCategory: AppAssets.qComIconCategory,
      AssetKeys.iconChart: AppAssets.qComIconChart,
      AssetKeys.iconDelete: AppAssets.qComIconDelete,
      AssetKeys.iconMenu: AppAssets.qComIconMenu,
      AssetKeys.iconExpense: AppAssets.qComIconExpense,
      AssetKeys.iconIncome: AppAssets.qComIconIncome,
      AssetKeys.iconUndo: AppAssets.qComIconUndo,
      AssetKeys.iconNotes: AppAssets.qComIconCategory,
      AssetKeys.iconTheme: AppAssets.qComIconSettings,
      AssetKeys.iconWallet: AppAssets.qComIconCategory,
      AssetKeys.iconSync: AppAssets.qComIconCategory,
      AssetKeys.iconPrivacy: AppAssets.qComIconCategory,
      AssetKeys.iconBooks: AppAssets.qComIconCategory,
      AssetKeys.iconRestaurant: AppAssets.qComIconCategory,
      AssetKeys.iconSalary: AppAssets.qComIconIncome, // Map to income icon
    },
    categoryIcons: {
      AssetKeys.catGroceries: AppAssets.qCatIconGroceries,
      AssetKeys.catRent: AppAssets.qCatIconRent,
      AssetKeys.catUtilities: AppAssets.qCatIconUtilities,
      AssetKeys.catFreelance: AppAssets.qCatIconFreelance,
      AssetKeys.catFood: AppAssets.qCatIconGroceries,
      AssetKeys.catTransport: AppAssets.qComIconExpense,
      AssetKeys.catEntertainment: AppAssets.qComIconExpense,
      AssetKeys.catMedical: AppAssets.qComIconExpense,
      AssetKeys.catSalary: AppAssets.qComIconIncome,
      AssetKeys.catSubscription: AppAssets.qCatIconUtilities,
      AssetKeys.catHousing: AppAssets.qCatIconRent,
      AssetKeys.catBonus: AppAssets.qComIconIncome,
      AssetKeys.catGift: AppAssets.qComIconIncome,
      AssetKeys.catInterest: AppAssets.qComIconIncome,
      AssetKeys.catOther: AppAssets.qComIconCategory,
      AssetKeys.catBank: AppAssets.qComIconCategory,
      AssetKeys.catCash: AppAssets.qComIconCategory,
      AssetKeys.catCrypto: AppAssets.qComIconCategory,
      AssetKeys.catInvestment: AppAssets.qComIconChart,
    },
    illustrations: {
      AssetKeys.illuEmptyTransactions: AppAssets.qIlluEmptyTransactions,
      'empty_dark_sky': AppAssets.qIlluEmptyDarkSky, // Keep specific if used
      AssetKeys.illuEmptyAddFirst: AppAssets.qIlluEmptyAddFirst,
      AssetKeys.illuEmptyFilter: AppAssets.qIlluEmptyTransactions,
    },
    charts: {
      AssetKeys.chartBarTemplate: AppAssets.qChartBarTemplate,
      AssetKeys.chartProgressExpense: AppAssets.qChartProgressExpense,
      AssetKeys.chartProgressIncome: AppAssets.qChartProgressIncome,
      AssetKeys.chartPieCategory: AppAssets.qChartPieCategory,
      AssetKeys.chartStatWidgetFrame: AppAssets.qChartStatWidgetFrame,
      // Map other generic chart keys if needed
      AssetKeys.chartBalanceIndicator:
          AppAssets.qChartProgressIncome, // Example mapping
    },
    nodeAssets: {}, // No nodes
  );

  static final _p1Assets = _baseAssets.copyWith(fabGlow: AppAssets.qP1FabGlow);
  static final _p2Assets = _baseAssets.copyWith(fabGlow: AppAssets.qP2FabGlow);
  static final _p3Assets = _baseAssets.copyWith(fabGlow: AppAssets.qP3FabGlow);
  static final _p4Assets = _baseAssets.copyWith(fabGlow: AppAssets.qP4FabGlow);

  // Palette Definitions remain the same...
  static final Map<String, QuantumConfig> palettes = {
    AppTheme.quantumPalette1: QuantumConfig(
      paletteIdentifier: AppTheme.quantumPalette1,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p1Assets,
      darkAssets: _p1Assets,
    ),
    AppTheme.quantumPalette2: QuantumConfig(
      paletteIdentifier: AppTheme.quantumPalette2,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p2Assets,
      darkAssets: _p2Assets,
    ),
    AppTheme.quantumPalette3: QuantumConfig(
      paletteIdentifier: AppTheme.quantumPalette3,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p3Assets,
      darkAssets: _p3Assets,
    ),
    AppTheme.quantumPalette4: QuantumConfig(
      paletteIdentifier: AppTheme.quantumPalette4,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p4Assets,
      darkAssets: _p4Assets,
    ),
  };

  static IThemePaletteConfig getConfig(String paletteIdentifier) {
    return palettes[paletteIdentifier] ?? palettes[AppTheme.quantumPalette1]!;
  }
}
