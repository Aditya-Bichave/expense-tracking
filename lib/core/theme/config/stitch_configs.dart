import 'package:flutter/material.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'theme_config_interface.dart';

class StitchConfig implements IThemePaletteConfig {
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

  @override
  final LayoutDensity layoutDensity = LayoutDensity.comfortable;
  @override
  final CardStyle cardStyle = CardStyle.glass;
  @override
  final Duration primaryAnimationDuration = const Duration(milliseconds: 300);
  @override
  final ListEntranceAnimation listEntranceAnimation =
      ListEntranceAnimation.fadeSlide;
  @override
  final bool preferDataTableForLists = false;

  @override
  final Color? incomeGlowColorLight = const Color(0xAA13EC5B);
  @override
  final Color? expenseGlowColorLight = const Color(0xAAFF4D4D);
  @override
  final Color? incomeGlowColorDark = const Color(0xAA13EC5B);
  @override
  final Color? expenseGlowColorDark = const Color(0xAAFF4D4D);

  const StitchConfig({
    required this.paletteIdentifier,
    required this.lightColorScheme,
    required this.darkColorScheme,
    required this.lightAssets,
    required this.darkAssets,
  });
}

abstract class StitchConfigs {
  static const _primaryGreen = Color(0xFF13EC5B);
  static const _bgDark = Color(0xFF102216);
  static const _bgLight = Color(0xFFF6F8F6);
  static const _debtRed = Color(0xFFFF4D4D);

  // Reuse Elemental assets for now as placeholders
  static const _baseAssets = ThemeAssetPaths(
    mainBackgroundLight: AppAssets.elBgLight,
    mainBackgroundDark: AppAssets.elBgDark,
    cardBackground: AppAssets.elBgCardSurface,
    divider: null,
    focusRing: null,
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
      AssetKeys.iconExpense: AppAssets.elComIconCategory,
      AssetKeys.iconIncome: AppAssets.elComIconCategory,
      AssetKeys.iconUndo: AppAssets.elComIconBack,
      AssetKeys.iconSync: AppAssets.elComIconCategory,
      AssetKeys.iconPrivacy: AppAssets.elComIconCategory,
      AssetKeys.iconBooks: AppAssets.elComIconCategory,
      AssetKeys.iconRestaurant: AppAssets.elComIconCategory,
      AssetKeys.iconSalary: AppAssets.elComIconCategory,
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
      AssetKeys.catRent: AppAssets.elCatIconFood,
    },
    illustrations: {
      AssetKeys.illuEmptyTransactions: AppAssets.elIlluEmptyAddTransaction,
      AssetKeys.illuEmptyWallet: AppAssets.elIlluEmptyWallet,
      AssetKeys.illuEmptyCalendar: AppAssets.elIlluEmptyCalendar,
      AssetKeys.illuEmptyFilter: AppAssets.elIlluEmptyCalendar,
      AssetKeys.illuEmptyAddFirst: AppAssets.elIlluEmptyAddTransaction,
    },
    charts: {
      AssetKeys.chartBarSpending: AppAssets.elChartBarSpending,
      AssetKeys.chartChipExpense: AppAssets.elChartChipExpense,
      AssetKeys.chartChipIncome: AppAssets.elChartChipIncome,
      AssetKeys.chartCircleBudget: AppAssets.elChartCircleBudget,
      AssetKeys.chartHorizontalBar: AppAssets.elChartHorizontalBar,
      AssetKeys.chartStatCardFrame: AppAssets.elChartStatCardFrame,
      AssetKeys.chartBalanceIndicator: AppAssets.elChartBarSpending,
    },
    nodeAssets: {},
  );

  static final Map<String, StitchConfig> palettes = {
    AppTheme.stitchPalette1: StitchConfig(
      paletteIdentifier: AppTheme.stitchPalette1,
      lightColorScheme: ColorScheme.fromSeed(
        seedColor: _primaryGreen,
        primary: _primaryGreen,
        background: _bgLight,
        surface: Colors.white,
        onSurface: Colors.black,
        error: _debtRed,
        brightness: Brightness.light,
      ),
      darkColorScheme: ColorScheme.fromSeed(
        seedColor: _primaryGreen,
        primary: _primaryGreen,
        background: _bgDark,
        surface: const Color(0xFF1C271F), // Glass fallback
        onSurface: Colors.white,
        error: _debtRed,
        brightness: Brightness.dark,
      ),
      lightAssets: _baseAssets,
      darkAssets: _baseAssets,
    ),
  };

  static IThemePaletteConfig getConfig(String paletteIdentifier) {
    return palettes[paletteIdentifier] ?? palettes[AppTheme.stitchPalette1]!;
  }
}
