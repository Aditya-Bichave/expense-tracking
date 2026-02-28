import 'package:flutter/material.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For palette identifiers
import 'theme_config_interface.dart'; // Import interface
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

// Config class implements the interface
class AetherConfig implements IThemePaletteConfig {
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
  // Aether Specific Defaults
  @override
  final LayoutDensity layoutDensity = LayoutDensity.spacious;
  @override
  final CardStyle cardStyle = CardStyle.floating;
  @override
  final Duration primaryAnimationDuration = const Duration(milliseconds: 450);
  @override
  final ListEntranceAnimation listEntranceAnimation =
      ListEntranceAnimation.shimmerSweep;
  @override
  final bool preferDataTableForLists = false;
  // Passed via constructor for Aether
  @override
  final Color? incomeGlowColorLight;
  @override
  final Color? expenseGlowColorLight;
  @override
  final Color? incomeGlowColorDark;
  @override
  final Color? expenseGlowColorDark;
  // Aether specific overrides for new properties (optional)
  final EdgeInsets? pagePadding = const BridgeEdgeInsets.only(
    top: 0,
    left: 0,
    right: 0,
    bottom: 16,
  ); // No top padding if AppBar is transparent/gone
  final EdgeInsets? cardOuterPadding = const BridgeEdgeInsets.symmetric(
    horizontal: 16.0,
    vertical: 10.0,
  );
  final EdgeInsets? cardInnerPadding = const BridgeEdgeInsets.symmetric(
    horizontal: 20.0,
    vertical: 16.0,
  );
  final Duration? mediumDuration = const Duration(milliseconds: 450);
  final Duration? listAnimationDelay = const Duration(milliseconds: 80);

  const AetherConfig({
    required this.paletteIdentifier,
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.lightAssets,
    required this.darkAssets,
    required this.incomeGlowColorLight,
    required this.expenseGlowColorLight,
    required this.incomeGlowColorDark,
    required this.expenseGlowColorDark,
    // Allow overriding defaults if needed
    // this.layoutDensity = LayoutDensity.spacious,
    // etc.
  });
}

abstract class AetherConfigs {
  // Base assets definition using AssetKeys
  static const _baseAssets = ThemeAssetPaths(
    // Backgrounds handled per-palette
    divider: null,
    focusRing: null, // No common SVGs
    commonIcons: {
      AssetKeys.iconAdd: AppAssets.aeComIconAdd,
      AssetKeys.iconSettings: AppAssets.aeComIconSettings,
      AssetKeys.iconCalendar: AppAssets.aeComIconCalendar,
      AssetKeys.iconCategory: AppAssets.aeComIconCategory,
      AssetKeys.iconNotes: AppAssets.aeComIconNotes,
      AssetKeys.iconTheme: AppAssets.aeComIconTheme,
      AssetKeys.iconSync: AppAssets.aeComIconSync,
      AssetKeys.iconPrivacy: AppAssets.aeComIconPrivacy,
      AssetKeys.iconBooks: AppAssets.aeComIconBooks,
      AssetKeys.iconRestaurant: AppAssets.aeComIconRestaurant,
      AssetKeys.iconSalary:
          AppAssets.aeComIconSalary, // Specific Aether common salary
      // Fallbacks
      AssetKeys.iconBack: AppAssets.aeComIconCategory,
      AssetKeys.iconChart: AppAssets.aeComIconCategory,
      AssetKeys.iconDelete: AppAssets.aeComIconCategory,
      AssetKeys.iconMenu: AppAssets.aeComIconSettings,
      AssetKeys.iconWallet: AppAssets.aeComIconCategory,
      AssetKeys.iconExpense: AppAssets.aeComIconCategory,
      AssetKeys.iconIncome: AppAssets.aeComIconCategory,
      AssetKeys.iconUndo: AppAssets.aeComIconSync,
    },
    categoryIcons: {
      // Base mappings, overridden by palettes
      AssetKeys.catGroceries: AppAssets.aeComIconGroceries,
      AssetKeys.catSalary: AppAssets.aeComIconSalary,
      AssetKeys.catFood: AppAssets.aeComIconRestaurant,
      AssetKeys.catOther: AppAssets.aeComIconCategory,
      // ... map other common ones like bank, cash etc. to generic fallbacks
      AssetKeys.catBank: AppAssets.aeComIconCategory,
      AssetKeys.catCash: AppAssets.aeComIconCategory,
      AssetKeys.catTransport: AppAssets.aeComIconCategory,
      AssetKeys.catEntertainment: AppAssets.aeComIconCategory,
      AssetKeys.catMedical: AppAssets.aeComIconCategory,
      AssetKeys.catSubscription: AppAssets.aeComIconCategory,
      AssetKeys.catUtilities: AppAssets.aeComIconCategory,
      AssetKeys.catRent: AppAssets.aeComIconCategory,
      AssetKeys.catFreelance: AppAssets.aeComIconSalary,
      AssetKeys.catHousing: AppAssets.aeComIconCategory,
      AssetKeys.catBonus: AppAssets.aeComIconSalary,
      AssetKeys.catGift: AppAssets.aeComIconCategory,
      AssetKeys.catInterest: AppAssets.aeComIconCategory,
      AssetKeys.catCrypto: AppAssets.aeComIconCategory,
      AssetKeys.catInvestment: AppAssets.aeComIconCategory,
    },
    illustrations: {
      AssetKeys.illuEmptyTransactions: AppAssets.aeIlluEmptyStarscape,
      AssetKeys.illuEmptyAddFirst: AppAssets.aeIlluAddFirstTransaction,
      AssetKeys.illuPlanetIsland: AppAssets.aeIlluPlanetIsland,
      AssetKeys.illuEmptyFilter: AppAssets.aeIlluEmptyStarscape,
      // Map others if needed
    },
    charts: {
      AssetKeys.chartBalanceIndicator: AppAssets.aeChartBalanceCircle,
      AssetKeys.chartWeeklySparkline: AppAssets.aeChartWeeklySparkline,
      AssetKeys.chartTopCatIncome: AppAssets.aeChartTopCatIncome,
      // Keep specific keys if used by Aether widgets
      'top_cat_food': AppAssets.aeChartTopCatFood,
      'top_cat_bills': AppAssets.aeChartTopCatBills,
      'top_cat_entertainment': AppAssets.aeChartTopCatEntertainment,
    },
    // nodeAssets and fabGlow are per-palette
  );

  // Palette-specific assets remain the same structure as before...
  static final _p1Assets = _baseAssets.copyWith(
    /* Starfield specifics using AssetKeys */
    mainBackgroundDark: AppAssets.aeBgStarfield,
    mainBackgroundLight: AppAssets.aeBgStarfield,
    fabGlow: AppAssets.aeP1FabGlow,
    categoryIcons: {
      ..._baseAssets.categoryIcons,
      AssetKeys.catGroceries: AppAssets.aeP1IconGroceries,
    },
    nodeAssets: {
      AssetKeys.nodeIncome: AppAssets.aeP1PlanetIncome,
      AssetKeys.nodeExpense: AppAssets.aeP1PlanetExpense,
      AssetKeys.nodeBalance: AppAssets.aeP1StarsOverlay,
    },
  );
  static final _p2Assets = _baseAssets.copyWith(
    /* Garden specifics using AssetKeys */
    mainBackgroundDark: AppAssets.aeBgGarden,
    mainBackgroundLight: AppAssets.aeBgGarden,
    fabGlow: AppAssets.aeP2FabGlow,
    categoryIcons: {
      ..._baseAssets.categoryIcons,
      AssetKeys.catGroceries: AppAssets.aeP2IconGroceries,
    },
    nodeAssets: {
      AssetKeys.nodeIncome: AppAssets.aeP2ButterflyIncome,
      AssetKeys.nodeExpense: AppAssets.aeP2TreeExpense,
      AssetKeys.nodeBalance: AppAssets.aeP2LeafBalance,
    },
  );
  static final _p3Assets = _baseAssets.copyWith(
    /* Mystic specifics using AssetKeys */
    mainBackgroundDark: AppAssets.aeBgMystic,
    mainBackgroundLight: AppAssets.aeBgMystic,
    fabGlow: AppAssets.aeP3FabGlow,
    categoryIcons: {
      ..._baseAssets.categoryIcons,
      AssetKeys.catGroceries: AppAssets.aeP3IconGroceries,
    },
    nodeAssets: {
      AssetKeys.nodeIncome: AppAssets.aeP3MysticEyeIncome,
      AssetKeys.nodeExpense: AppAssets.aeP3WandExpense,
      AssetKeys.nodeBalance: AppAssets.aeP3OrbBalance,
    },
  );
  static final _p4Assets = _baseAssets.copyWith(
    /* Calm Sky specifics using AssetKeys */
    mainBackgroundDark: AppAssets.aeBgCalm,
    mainBackgroundLight: AppAssets.aeBgCalm,
    fabGlow: AppAssets.aeP4FabGlow,
    categoryIcons: {
      ..._baseAssets.categoryIcons,
      AssetKeys.catGroceries: AppAssets.aeP4IconGroceries,
    },
    nodeAssets: {
      AssetKeys.nodeIncome: AppAssets.aeP4CloudIncome,
      AssetKeys.nodeExpense: AppAssets.aeP4RainExpense,
      AssetKeys.nodeBalance: AppAssets.aeP4MoonBalance,
    },
  );

  // Palette Definitions remain the same...
  static final Map<String, AetherConfig> palettes = {
    AppTheme.aetherPalette1: AetherConfig(
      paletteIdentifier: AppTheme.aetherPalette1,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p1Assets,
      darkAssets: _p1Assets,
      incomeGlowColorLight: const Color(0xAA00BFA5),
      expenseGlowColorLight: const Color(0xAAEF5350),
      incomeGlowColorDark: const Color(0xAA00FFAA),
      expenseGlowColorDark: const Color(0xAAFF6B81),
    ),
    AppTheme.aetherPalette2: AetherConfig(
      /* ... Garden ... */
      paletteIdentifier: AppTheme.aetherPalette2,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p2Assets,
      darkAssets: _p2Assets,
      incomeGlowColorLight: const Color(0xAA00BFA5),
      expenseGlowColorLight: const Color(0xAAFF6E40),
      incomeGlowColorDark: const Color(0xAA88FFC2),
      expenseGlowColorDark: const Color(0xAAFF7043),
    ),
    AppTheme.aetherPalette3: AetherConfig(
      /* ... Mystic ... */
      paletteIdentifier: AppTheme.aetherPalette3,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p3Assets,
      darkAssets: _p3Assets,
      incomeGlowColorLight: const Color(0xAA00BFA5),
      expenseGlowColorLight: const Color(0xAADD2C00),
      incomeGlowColorDark: const Color(0xAA00E676),
      expenseGlowColorDark: const Color(0xAAFF3D00),
    ),
    AppTheme.aetherPalette4: AetherConfig(
      /* ... Calm Sky ... */
      paletteIdentifier: AppTheme.aetherPalette4,
      lightColorScheme: const ColorScheme.light(
        /* ... */ brightness: Brightness.light,
      ),
      darkColorScheme: const ColorScheme.dark(
        /* ... */ brightness: Brightness.dark,
      ),
      lightAssets: _p4Assets,
      darkAssets: _p4Assets,
      incomeGlowColorLight: const Color(0xAA26A69A),
      expenseGlowColorLight: const Color(0xAAE57373),
      incomeGlowColorDark: const Color(0xAA00DFA2),
      expenseGlowColorDark: const Color(0xAAF08080),
    ),
  };

  static IThemePaletteConfig getConfig(String paletteIdentifier) {
    return palettes[paletteIdentifier] ?? palettes[AppTheme.aetherPalette1]!;
  }
}
