// lib/core/theme/app_mode_theme.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Import dart:ui for lerpDouble
// Import asset keys

// --- Enums ---
enum LayoutDensity { compact, comfortable, spacious }

enum CardStyle { flat, elevated, floating }

enum ListEntranceAnimation {
  none,
  fadeSlide,
  shimmerSweep
} // Keep for potential future use

// --- Asset Keys ---
class AssetKeys {
  // Common Icons
  static const String iconAdd = 'add';
  static const String iconSettings = 'settings';
  static const String iconBack = 'back';
  static const String iconCalendar = 'calendar';
  static const String iconCategory = 'category';
  static const String iconChart = 'chart';
  static const String iconDelete = 'delete';
  static const String iconMenu = 'menu';
  static const String iconNotes = 'notes';
  static const String iconTheme = 'theme';
  static const String iconWallet = 'wallet';
  static const String iconExpense = 'expense';
  static const String iconIncome = 'income';
  static const String iconUndo = 'undo';
  static const String iconSync = 'sync';
  static const String iconPrivacy = 'privacy';
  static const String iconBooks = 'books';
  static const String iconRestaurant = 'restaurant';
  static const String iconSalary = 'salary'; // Added common salary

  // Illustrations
  static const String illuEmptyTransactions = 'empty_transactions';
  static const String illuEmptyAddFirst = 'empty_add_first';
  static const String illuEmptyWallet = 'empty_wallet';
  static const String illuEmptyCalendar = 'empty_calendar';
  static const String illuEmptyFilter = 'empty_filter';
  static const String illuPlanetIsland = 'planet_island';
  static const String illuEmptyStarscape = 'empty_starscape';

  // Charts
  static const String chartBalanceIndicator = 'balance_indicator';
  static const String chartWeeklySparkline = 'weekly_sparkline';
  static const String chartTopCatIncome = 'top_cat_income';
  // Add other generic chart keys as needed
  static const String chartBarSpending = 'bar_spending';
  static const String chartChipExpense = 'chip_expense';
  static const String chartChipIncome = 'chip_income';
  static const String chartCircleBudget = 'circle_budget_usage';
  static const String chartHorizontalBar = 'horizontal_bar_indicator';
  static const String chartStatCardFrame = 'stat_card_frame'; // Elemental
  static const String chartBarTemplate = 'bar_generic'; // Quantum
  static const String chartProgressExpense = 'progress_expense'; // Quantum
  static const String chartProgressIncome = 'progress_income'; // Quantum
  static const String chartPieCategory = 'pie_category'; // Quantum
  static const String chartStatWidgetFrame = 'stat_widget_frame'; // Quantum
  static const String chartTopCatBills =
      'top_category_bills'; // Aether specific
  static const String chartTopCatEntertainment =
      'top_category_entertainment'; // Aether specific
  static const String chartTopCatFood = 'top_category_food'; // Aether specific

  // Category Icons (Use lowercase names as keys)
  static const String catFood = 'food';
  static const String catGroceries = 'groceries';
  static const String catTransport = 'transport';
  static const String catEntertainment = 'entertainment';
  static const String catMedical = 'medical';
  static const String catSalary = 'salary'; // Income cat
  static const String catSubscription = 'subscription';
  static const String catUtilities = 'utilities';
  static const String catRent = 'rent';
  static const String catFreelance = 'freelance'; // Income cat
  static const String catHousing = 'housing';
  static const String catBonus = 'bonus'; // Income cat
  static const String catGift = 'gift'; // Income cat
  static const String catInterest = 'interest'; // Income cat
  static const String catOther = 'other';
  static const String catBank = 'bank'; // Account type
  static const String catCash = 'cash'; // Account type
  static const String catCrypto = 'crypto'; // Account type
  static const String catInvestment = 'investment'; // Account type

  // Node keys (Aether)
  static const String nodeIncome = 'income_node';
  static const String nodeExpense = 'expense_node';
  static const String nodeBalance = 'balance_node';
}

// --- Theme Asset Paths ---
@immutable
class ThemeAssetPaths {
  // Keep constructor and properties the same
  const ThemeAssetPaths({
    this.fabGlow,
    this.divider,
    this.focusRing,
    this.cardBackground,
    this.mainBackgroundLight,
    this.mainBackgroundDark,
    this.commonIcons = const {},
    this.categoryIcons = const {},
    this.illustrations = const {},
    this.charts = const {},
    this.nodeAssets = const {},
  });

  final String? fabGlow;
  final String? divider;
  final String? focusRing;
  final String? cardBackground;
  final String? mainBackgroundLight;
  final String? mainBackgroundDark;
  final Map<String, String> commonIcons;
  final Map<String, String> categoryIcons;
  final Map<String, String> illustrations;
  final Map<String, String> charts;
  final Map<String, String> nodeAssets;

  // Generic accessor
  String? _getPath(Map<String, String> map, String key) {
    final path = map[key.toLowerCase()];
    return path;
  }

  // Accessor Methods (provide defaultPath as empty string for clarity)
  String getCommonIcon(String key, {String defaultPath = ''}) =>
      _getPath(commonIcons, key) ?? defaultPath;
  String getCategoryIcon(String key, {String defaultPath = ''}) =>
      _getPath(categoryIcons, key) ?? defaultPath;
  String getIllustration(String key, {String defaultPath = ''}) =>
      _getPath(illustrations, key) ?? defaultPath;
  String getChartAsset(String key, {String defaultPath = ''}) =>
      _getPath(charts, key) ?? defaultPath;
  String getNodeAsset(String key, {String defaultPath = ''}) =>
      _getPath(nodeAssets, key) ?? defaultPath;

  // --- copyWith (Ensure all properties are included) ---
  ThemeAssetPaths copyWith({
    String? fabGlow,
    String? divider,
    String? focusRing,
    String? cardBackground,
    String? mainBackgroundLight,
    String? mainBackgroundDark,
    Map<String, String>? commonIcons,
    Map<String, String>? categoryIcons,
    Map<String, String>? illustrations,
    Map<String, String>? charts,
    Map<String, String>? nodeAssets,
  }) {
    return ThemeAssetPaths(
      fabGlow: fabGlow ?? this.fabGlow,
      divider: divider ?? this.divider,
      focusRing: focusRing ?? this.focusRing,
      cardBackground: cardBackground ?? this.cardBackground,
      mainBackgroundLight: mainBackgroundLight ?? this.mainBackgroundLight,
      mainBackgroundDark: mainBackgroundDark ?? this.mainBackgroundDark,
      commonIcons: commonIcons ?? this.commonIcons,
      categoryIcons: categoryIcons ?? this.categoryIcons,
      illustrations: illustrations ?? this.illustrations,
      charts: charts ?? this.charts,
      nodeAssets: nodeAssets ?? this.nodeAssets,
    );
  }
}

// --- App Mode Theme Extension ---
@immutable
class AppModeTheme extends ThemeExtension<AppModeTheme> {
  const AppModeTheme({
    required this.modeId,
    required this.layoutDensity,
    required this.cardStyle,
    required this.assets,
    required this.preferDataTableForLists,
    required this.primaryAnimationDuration, // Keep for compatibility or specific uses
    required this.listEntranceAnimation,
    this.incomeGlowColor,
    this.expenseGlowColor,
    // --- NEW PROPERTIES ---
    this.pagePadding = const EdgeInsets.all(16.0),
    this.cardOuterPadding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
    this.cardInnerPadding = const EdgeInsets.all(16.0),
    this.listItemPadding =
        const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
    this.mediumDuration =
        const Duration(milliseconds: 300), // Default medium duration
    this.fastDuration =
        const Duration(milliseconds: 150), // Default fast duration
    this.primaryCurve = Curves.easeInOut, // Default curve
    this.listAnimationDelay =
        const Duration(milliseconds: 50), // Default list stagger
    this.listAnimationDuration =
        const Duration(milliseconds: 400), // Default list item duration
  });

  // Existing properties
  final String modeId;
  final LayoutDensity layoutDensity;
  final CardStyle cardStyle;
  final ThemeAssetPaths assets;
  final bool preferDataTableForLists;
  final Duration primaryAnimationDuration;
  final ListEntranceAnimation listEntranceAnimation;
  final Color? incomeGlowColor;
  final Color? expenseGlowColor;

  // --- NEW PROPERTIES ---
  final EdgeInsets pagePadding;
  final EdgeInsets cardOuterPadding;
  final EdgeInsets cardInnerPadding;
  final EdgeInsets listItemPadding;
  final Duration mediumDuration;
  final Duration fastDuration;
  final Curve primaryCurve;
  final Duration listAnimationDelay;
  final Duration listAnimationDuration;

  @override
  AppModeTheme copyWith({
    String? modeId,
    LayoutDensity? layoutDensity,
    CardStyle? cardStyle,
    ThemeAssetPaths? assets,
    bool? preferDataTableForLists,
    Duration? primaryAnimationDuration,
    ListEntranceAnimation? listEntranceAnimation,
    ValueGetter<Color?>? incomeGlowColor,
    ValueGetter<Color?>? expenseGlowColor,
    // New properties
    EdgeInsets? pagePadding,
    EdgeInsets? cardOuterPadding,
    EdgeInsets? cardInnerPadding,
    EdgeInsets? listItemPadding,
    Duration? mediumDuration,
    Duration? fastDuration,
    Curve? primaryCurve,
    Duration? listAnimationDelay,
    Duration? listAnimationDuration,
  }) {
    return AppModeTheme(
      modeId: modeId ?? this.modeId,
      layoutDensity: layoutDensity ?? this.layoutDensity,
      cardStyle: cardStyle ?? this.cardStyle, assets: assets ?? this.assets,
      preferDataTableForLists:
          preferDataTableForLists ?? this.preferDataTableForLists,
      primaryAnimationDuration:
          primaryAnimationDuration ?? this.primaryAnimationDuration,
      listEntranceAnimation:
          listEntranceAnimation ?? this.listEntranceAnimation,
      incomeGlowColor:
          incomeGlowColor != null ? incomeGlowColor() : this.incomeGlowColor,
      expenseGlowColor:
          expenseGlowColor != null ? expenseGlowColor() : this.expenseGlowColor,
      // Assign new properties
      pagePadding: pagePadding ?? this.pagePadding,
      cardOuterPadding: cardOuterPadding ?? this.cardOuterPadding,
      cardInnerPadding: cardInnerPadding ?? this.cardInnerPadding,
      listItemPadding: listItemPadding ?? this.listItemPadding,
      mediumDuration: mediumDuration ?? this.mediumDuration,
      fastDuration: fastDuration ?? this.fastDuration,
      primaryCurve: primaryCurve ?? this.primaryCurve,
      listAnimationDelay: listAnimationDelay ?? this.listAnimationDelay,
      listAnimationDuration:
          listAnimationDuration ?? this.listAnimationDuration,
    );
  }

  @override
  AppModeTheme lerp(ThemeExtension<AppModeTheme>? other, double t) {
    if (other is! AppModeTheme) return this;
    return AppModeTheme(
      modeId: t < 0.5 ? modeId : other.modeId,
      layoutDensity: t < 0.5 ? layoutDensity : other.layoutDensity,
      cardStyle: t < 0.5 ? cardStyle : other.cardStyle,
      assets: t < 0.5 ? assets : other.assets,
      preferDataTableForLists:
          t < 0.5 ? preferDataTableForLists : other.preferDataTableForLists,
      primaryAnimationDuration: Duration(
          milliseconds: ui
              .lerpDouble(primaryAnimationDuration.inMilliseconds,
                  other.primaryAnimationDuration.inMilliseconds, t)!
              .round()),
      listEntranceAnimation:
          t < 0.5 ? listEntranceAnimation : other.listEntranceAnimation,
      incomeGlowColor: Color.lerp(incomeGlowColor, other.incomeGlowColor, t),
      expenseGlowColor: Color.lerp(expenseGlowColor, other.expenseGlowColor, t),
      // Lerp new properties
      pagePadding:
          EdgeInsets.lerp(pagePadding, other.pagePadding, t) ?? pagePadding,
      cardOuterPadding:
          EdgeInsets.lerp(cardOuterPadding, other.cardOuterPadding, t) ??
              cardOuterPadding,
      cardInnerPadding:
          EdgeInsets.lerp(cardInnerPadding, other.cardInnerPadding, t) ??
              cardInnerPadding,
      listItemPadding:
          EdgeInsets.lerp(listItemPadding, other.listItemPadding, t) ??
              listItemPadding,
      mediumDuration: Duration(
          milliseconds: ui
              .lerpDouble(mediumDuration.inMilliseconds,
                  other.mediumDuration.inMilliseconds, t)!
              .round()),
      fastDuration: Duration(
          milliseconds: ui
              .lerpDouble(fastDuration.inMilliseconds,
                  other.fastDuration.inMilliseconds, t)!
              .round()),
      primaryCurve: t < 0.5 ? primaryCurve : other.primaryCurve,
      listAnimationDelay: Duration(
          milliseconds: ui
              .lerpDouble(listAnimationDelay.inMilliseconds,
                  other.listAnimationDelay.inMilliseconds, t)!
              .round()),
      listAnimationDuration: Duration(
          milliseconds: ui
              .lerpDouble(listAnimationDuration.inMilliseconds,
                  other.listAnimationDuration.inMilliseconds, t)!
              .round()),
    );
  }

  List<Object?> get props => [
        modeId, layoutDensity, cardStyle, assets, preferDataTableForLists,
        primaryAnimationDuration, listEntranceAnimation, incomeGlowColor,
        expenseGlowColor,
        // New properties
        pagePadding, cardOuterPadding, cardInnerPadding, listItemPadding,
        mediumDuration, fastDuration, primaryCurve, listAnimationDelay,
        listAnimationDuration,
      ];
}

// Keep context extension
extension ThemeContextExtension on BuildContext {
  AppModeTheme? get modeTheme => Theme.of(this).extension<AppModeTheme>();
}
