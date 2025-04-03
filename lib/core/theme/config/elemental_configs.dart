// lib/core/theme/config/elemental_configs.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For palette identifiers
import 'theme_config_interface.dart'; // Import interface

// Config class implements the interface
class ElementalConfig implements IThemePaletteConfig {
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
  // Define defaults or allow overrides for Elemental
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
  // Elemental specific overrides for new properties (optional)
  final EdgeInsets? cardOuterPadding;
  final EdgeInsets? cardInnerPadding;
  final Duration? mediumDuration;

  const ElementalConfig({
    required this.paletteIdentifier,
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.lightAssets,
    required this.darkAssets,
    // Elemental Defaults (can be overridden if passed in constructor)
    this.layoutDensity = LayoutDensity.comfortable,
    this.cardStyle = CardStyle.elevated,
    this.primaryAnimationDuration = const Duration(milliseconds: 300),
    this.listEntranceAnimation = ListEntranceAnimation.fadeSlide,
    this.preferDataTableForLists = false,
    this.incomeGlowColorLight = const Color(0x664CAF50),
    this.expenseGlowColorLight = const Color(0x66E53935),
    this.incomeGlowColorDark = const Color(0x66C8E6C9),
    this.expenseGlowColorDark = const Color(0x66FFCDD2),
    // Example: Override specific padding for elemental
    this.cardOuterPadding =
        const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
    this.cardInnerPadding, // = null, use AppModeTheme default
    this.mediumDuration, // = null, use AppModeTheme default
  });
}

abstract class ElementalConfigs {
  // Base assets definition using AssetKeys
  static const _baseAssets = ThemeAssetPaths(
    mainBackgroundLight: AppAssets.elBgLight,
    mainBackgroundDark: AppAssets.elBgDark,
    cardBackground: AppAssets.elBgCardSurface,
    divider: AppAssets.elDecoDivider,
    focusRing: AppAssets.elDecoFocusRing,
    commonIcons: {
      AssetKeys.iconAdd: AppAssets.elComIconAdd,
      AssetKeys.iconSettings: AppAssets.elComIconSettings,
      AssetKeys.iconBack: AppAssets.elComIconBack,
      AssetKeys.iconCalendar: AppAssets.elComIconCalendar,
      AssetKeys.iconCategory: AppAssets.elComIconCategory,
      AssetKeys.iconChart: AppAssets.elComIconChart,
      AssetKeys.iconDelete: AppAssets.elComIconDelete,
      AssetKeys.iconMenu: AppAssets.elComIconMenu,
      AssetKeys.iconNotes: AppAssets.elComIconNotes,
      AssetKeys.iconTheme: AppAssets.elComIconTheme,
      AssetKeys.iconWallet: AppAssets.elComIconWallet,
      AssetKeys.iconExpense: AppAssets.elComIconCategory, // Fallback
      AssetKeys.iconIncome: AppAssets.elComIconCategory, // Fallback
      AssetKeys.iconUndo: AppAssets.elComIconBack, // Fallback
      AssetKeys.iconSync: AppAssets.elComIconCategory,
      AssetKeys.iconPrivacy: AppAssets.elComIconCategory,
      AssetKeys.iconBooks: AppAssets.elComIconCategory,
      AssetKeys.iconRestaurant: AppAssets.elComIconCategory,
      AssetKeys.iconSalary: AppAssets
          .elComIconCategory, // Use fallback if no specific elemental salary icon
    },
    categoryIcons: {
      AssetKeys.catFood: AppAssets.elCatIconFood,
      AssetKeys.catGroceries: AppAssets.elCatIconGroceries,
      AssetKeys.catTransport: AppAssets.elCatIconTransport,
      AssetKeys.catEntertainment: AppAssets.elCatIconEntertainment,
      AssetKeys.catMedical: AppAssets.elCatIconMedical,
      AssetKeys.catSalary: AppAssets.elCatIconSalary,
      AssetKeys.catSubscription: AppAssets.elCatIconSubscription,
      AssetKeys.catUtilities: AppAssets.elCatIconSubscription,
      AssetKeys.catHousing: AppAssets.elCatIconFood,
      AssetKeys.catBonus: AppAssets.elCatIconSalary,
      AssetKeys.catFreelance: AppAssets.elCatIconSalary,
      AssetKeys.catGift: AppAssets.elCatIconSalary,
      AssetKeys.catInterest: AppAssets.elCatIconSalary,
      AssetKeys.catOther: AppAssets.elComIconCategory,
      AssetKeys.catBank: AppAssets.elComIconWallet,
      AssetKeys.catCash: AppAssets.elComIconWallet,
      AssetKeys.catCrypto: AppAssets.elComIconWallet,
      AssetKeys.catInvestment: AppAssets.elComIconChart,
      // Ensure all keys from AssetKeys.cat* are mapped or have fallbacks
      AssetKeys.catRent: AppAssets.elCatIconFood, // Example fallback
    },
    illustrations: {
      AssetKeys.illuEmptyTransactions: AppAssets.elIlluEmptyAddTransaction,
      AssetKeys.illuEmptyWallet: AppAssets.elIlluEmptyWallet,
      AssetKeys.illuEmptyCalendar: AppAssets.elIlluEmptyCalendar,
      AssetKeys.illuEmptyFilter: AppAssets.elIlluEmptyCalendar,
      // Map other illustration keys if needed
      AssetKeys.illuEmptyAddFirst: AppAssets.elIlluEmptyAddTransaction,
    },
    charts: {
      AssetKeys.chartBarSpending: AppAssets.elChartBarSpending,
      AssetKeys.chartChipExpense: AppAssets.elChartChipExpense,
      AssetKeys.chartChipIncome: AppAssets.elChartChipIncome,
      AssetKeys.chartCircleBudget: AppAssets.elChartCircleBudget,
      AssetKeys.chartHorizontalBar: AppAssets.elChartHorizontalBar,
      AssetKeys.chartStatCardFrame: AppAssets.elChartStatCardFrame,
      // Map other generic chart keys if needed
      AssetKeys.chartBalanceIndicator:
          AppAssets.elChartBarSpending, // Example mapping
    },
    nodeAssets: {}, // No node assets for Elemental
  );
  static final _p1Assets = _baseAssets.copyWith(fabGlow: AppAssets.elP1FabGlow);
  static final _p2Assets = _baseAssets.copyWith(fabGlow: AppAssets.elP2FabGlow);
  static final _p3Assets = _baseAssets.copyWith(fabGlow: AppAssets.elP3FabGlow);
  static final _p4Assets = _baseAssets.copyWith(fabGlow: AppAssets.elP4FabGlow);

  static final Map<String, ElementalConfig> palettes = {
    AppTheme.elementalPalette1: ElementalConfig(
      paletteIdentifier: AppTheme.elementalPalette1,
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A7BD5), brightness: Brightness.light),
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A7BD5), brightness: Brightness.dark),
      lightAssets: _p1Assets,
      darkAssets: _p1Assets,
    ),
    AppTheme.elementalPalette2: ElementalConfig(
      paletteIdentifier: AppTheme.elementalPalette2,
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF039BE5), brightness: Brightness.light),
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF039BE5), brightness: Brightness.dark),
      lightAssets: _p2Assets,
      darkAssets: _p2Assets,
    ),
    AppTheme.elementalPalette3: ElementalConfig(
      paletteIdentifier: AppTheme.elementalPalette3,
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0), brightness: Brightness.light),
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0), brightness: Brightness.dark),
      lightAssets: _p3Assets,
      darkAssets: _p3Assets,
    ),
    AppTheme.elementalPalette4: ElementalConfig(
      paletteIdentifier: AppTheme.elementalPalette4,
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBB86FC),
          brightness: Brightness.dark), // Use dark as light too
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBB86FC), brightness: Brightness.dark),
      lightAssets: _p4Assets, darkAssets: _p4Assets,
    ),
  };

  static IThemePaletteConfig getConfig(String paletteIdentifier) {
    return palettes[paletteIdentifier] ?? palettes[AppTheme.elementalPalette1]!;
  }
}
