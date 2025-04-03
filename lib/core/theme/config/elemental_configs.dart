// lib/core/theme/config/elemental_configs.dart
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // For palette identifiers
import 'theme_config_interface.dart'; // Import interface

class ElementalConfig implements IThemePaletteConfig {
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

  const ElementalConfig({
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.lightAssets,
    required this.darkAssets,
    this.layoutDensity = LayoutDensity.comfortable,
    this.cardStyle = CardStyle.elevated,
    this.primaryAnimationDuration = const Duration(milliseconds: 300),
    this.listEntranceAnimation = ListEntranceAnimation.fadeSlide,
    this.preferDataTableForLists = false,
    this.incomeGlowColorLight =
        const Color(0x664CAF50), // ~Colors.green[700].withOpacity(0.4)
    this.expenseGlowColorLight =
        const Color(0x66E53935), // ~Colors.red[700].withOpacity(0.4)
    this.incomeGlowColorDark =
        const Color(0x66C8E6C9), // ~Colors.greenAccent[100].withOpacity(0.4)
    this.expenseGlowColorDark =
        const Color(0x66FFCDD2), // ~Colors.redAccent[100].withOpacity(0.4)
  });
}

abstract class ElementalConfigs {
  // *** FIXED: Changed from static const to static final ***
  static const _commonAssets = ThemeAssetPaths(
    mainBackgroundLight: AppAssets.elBgLight,
    mainBackgroundDark: AppAssets.elBgDark,
    cardBackground: AppAssets.elBgCardSurface,
    divider: AppAssets.elDecoDivider,
    focusRing: AppAssets.elDecoFocusRing,
    commonIcons: {
      AppModeTheme.iconAdd: AppAssets.elComIconAdd,
      AppModeTheme.iconSettings: AppAssets.elComIconSettings,
      AppModeTheme.iconBack: AppAssets.elComIconBack,
      AppModeTheme.iconCalendar: AppAssets.elComIconCalendar,
      AppModeTheme.iconCategory: AppAssets.elComIconCategory,
      AppModeTheme.iconChart: AppAssets.elComIconChart,
      AppModeTheme.iconDelete: AppAssets.elComIconDelete,
      AppModeTheme.iconMenu: AppAssets.elComIconMenu,
      AppModeTheme.iconNotes: AppAssets.elComIconNotes,
      AppModeTheme.iconTheme: AppAssets.elComIconTheme,
      AppModeTheme.iconWallet: AppAssets.elComIconWallet,
    },
    categoryIcons: {
      'food': AppAssets.elCatIconFood,
      'groceries': AppAssets.elCatIconGroceries,
      'transport': AppAssets.elCatIconTransport,
      'entertainment': AppAssets.elCatIconEntertainment,
      'medical': AppAssets.elCatIconMedical,
      'salary': AppAssets.elCatIconSalary,
      'subscription': AppAssets.elCatIconSubscription,
      'utilities': AppAssets.elCatIconSubscription,
      'housing': AppAssets.elCatIconFood,
      'bonus': AppAssets.elCatIconSalary,
      'freelance': AppAssets.elCatIconSalary,
      'gift': AppAssets.elCatIconSalary,
      'interest': AppAssets.elCatIconSalary,
      'other': AppAssets.elComIconCategory,
      'bank': AppAssets.elComIconWallet,
      'cash': AppAssets.elComIconWallet,
      'crypto': AppAssets.elComIconWallet,
      'investment': AppAssets.elComIconChart,
    },
    illustrations: {
      'empty_transactions': AppAssets.elIlluEmptyAddTransaction,
      'empty_wallet': AppAssets.elIlluEmptyWallet,
      'empty_calendar': AppAssets.elIlluEmptyCalendar,
      'empty_filter': AppAssets.elIlluEmptyCalendar,
    },
    charts: {
      'bar_spending': AppAssets.elChartBarSpending,
      'chip_income': AppAssets.elChartChipIncome,
      'chip_expense': AppAssets.elChartChipExpense,
      'budget_usage_circle': AppAssets.elChartCircleBudget,
      'stat_card_frame': AppAssets.elChartStatCardFrame,
    },
    // fabGlow is palette specific, so leave it null here
  );

  // *** FIXED: Changed from static const to static final ***
  static final _p1Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.elP1FabGlow);
  static final _p2Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.elP2FabGlow);
  static final _p3Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.elP3FabGlow);
  static final _p4Assets =
      _commonAssets.copyWith(fabGlow: AppAssets.elP4FabGlow);

  static final Map<String, ElementalConfig> palettes = {
    // Use const for the ElementalConfig constructor as ColorScheme.fromSeed is const
    AppTheme.elementalPalette1: ElementalConfig(
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A7BD5), brightness: Brightness.light),
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A7BD5), brightness: Brightness.dark),
      lightAssets: _p1Assets,
      darkAssets: _p1Assets,
    ),
    AppTheme.elementalPalette2: ElementalConfig(
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF039BE5), brightness: Brightness.light),
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF039BE5), brightness: Brightness.dark),
      lightAssets: _p2Assets,
      darkAssets: _p2Assets,
    ),
    AppTheme.elementalPalette3: ElementalConfig(
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0), brightness: Brightness.light),
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF9C27B0), brightness: Brightness.dark),
      lightAssets: _p3Assets,
      darkAssets: _p3Assets,
    ),
    AppTheme.elementalPalette4: ElementalConfig(
      lightColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBB86FC),
          brightness: Brightness.dark), // Use dark as light too
      darkColorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFBB86FC), brightness: Brightness.dark),
      lightAssets: _p4Assets,
      darkAssets: _p4Assets,
    ),
  };

  static IThemePaletteConfig getConfig(String paletteIdentifier) {
    return palettes[paletteIdentifier] ??
        palettes[AppTheme.elementalPalette1]!; // Fallback
  }
}
