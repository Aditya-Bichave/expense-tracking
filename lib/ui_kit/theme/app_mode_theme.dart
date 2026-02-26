import 'package:flutter/material.dart';
import 'dart:ui' as ui;

// --- Enums ---
enum LayoutDensity { compact, comfortable, spacious }

enum CardStyle { flat, elevated, floating, glass }

enum ListEntranceAnimation { fadeSlide, scaleFade, shimmerSweep, none }

// --- Theme Asset Paths ---
@immutable
class ThemeAssetPaths {
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

  String getCommonIcon(String key, {String defaultPath = ''}) =>
      commonIcons[key.toLowerCase()] ?? defaultPath;
  String getCategoryIcon(String key, {String defaultPath = ''}) =>
      categoryIcons[key.toLowerCase()] ?? defaultPath;
  String getIllustration(String key, {String defaultPath = ''}) =>
      illustrations[key.toLowerCase()] ?? defaultPath;
  String getChartAsset(String key, {String defaultPath = ''}) =>
      charts[key.toLowerCase()] ?? defaultPath;
  String getNodeAsset(String key, {String defaultPath = ''}) =>
      nodeAssets[key.toLowerCase()] ?? defaultPath;

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
    required this.primaryAnimationDuration,
    required this.listEntranceAnimation,
    this.incomeGlowColor,
    this.expenseGlowColor,
    this.pagePadding = const EdgeInsets.all(16.0),
    this.cardOuterPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 8.0,
    ),
    this.cardInnerPadding = const EdgeInsets.all(16.0),
    this.listItemPadding = const EdgeInsets.symmetric(
      horizontal: 16.0,
      vertical: 12.0,
    ),
    this.mediumDuration = const Duration(milliseconds: 300),
    this.fastDuration = const Duration(milliseconds: 150),
    this.primaryCurve = Curves.easeInOut,
    this.listAnimationDelay = const Duration(milliseconds: 50),
    this.listAnimationDuration = const Duration(milliseconds: 400),
  });

  final String modeId;
  final LayoutDensity layoutDensity;
  final CardStyle cardStyle;
  final ThemeAssetPaths assets;
  final bool preferDataTableForLists;
  final Duration primaryAnimationDuration;
  final ListEntranceAnimation listEntranceAnimation;
  final Color? incomeGlowColor;
  final Color? expenseGlowColor;

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
    Color? incomeGlowColor,
    Color? expenseGlowColor,
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
      cardStyle: cardStyle ?? this.cardStyle,
      assets: assets ?? this.assets,
      preferDataTableForLists:
          preferDataTableForLists ?? this.preferDataTableForLists,
      primaryAnimationDuration:
          primaryAnimationDuration ?? this.primaryAnimationDuration,
      listEntranceAnimation:
          listEntranceAnimation ?? this.listEntranceAnimation,
      incomeGlowColor: incomeGlowColor ?? this.incomeGlowColor,
      expenseGlowColor: expenseGlowColor ?? this.expenseGlowColor,
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
      preferDataTableForLists: t < 0.5
          ? preferDataTableForLists
          : other.preferDataTableForLists,
      primaryAnimationDuration: Duration(
        milliseconds: ui
            .lerpDouble(
              primaryAnimationDuration.inMilliseconds,
              other.primaryAnimationDuration.inMilliseconds,
              t,
            )!
            .round(),
      ),
      listEntranceAnimation: t < 0.5
          ? listEntranceAnimation
          : other.listEntranceAnimation,
      incomeGlowColor: Color.lerp(incomeGlowColor, other.incomeGlowColor, t),
      expenseGlowColor: Color.lerp(expenseGlowColor, other.expenseGlowColor, t),
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
            .lerpDouble(
              mediumDuration.inMilliseconds,
              other.mediumDuration.inMilliseconds,
              t,
            )!
            .round(),
      ),
      fastDuration: Duration(
        milliseconds: ui
            .lerpDouble(
              fastDuration.inMilliseconds,
              other.fastDuration.inMilliseconds,
              t,
            )!
            .round(),
      ),
      primaryCurve: t < 0.5 ? primaryCurve : other.primaryCurve,
      listAnimationDelay: Duration(
        milliseconds: ui
            .lerpDouble(
              listAnimationDelay.inMilliseconds,
              other.listAnimationDelay.inMilliseconds,
              t,
            )!
            .round(),
      ),
      listAnimationDuration: Duration(
        milliseconds: ui
            .lerpDouble(
              listAnimationDuration.inMilliseconds,
              other.listAnimationDuration.inMilliseconds,
              t,
            )!
            .round(),
      ),
    );
  }
}

// Keep context extension
extension ThemeContextExtension on BuildContext {
  AppModeTheme? get modeTheme => Theme.of(this).extension<AppModeTheme>();
}

// --- Asset Keys ---
class AssetKeys {
  static const String cat = 'cat';
  static const String catBank = 'catbank';
  static const String catBonus = 'catbonus';
  static const String catCash = 'catcash';
  static const String catCrypto = 'catcrypto';
  static const String catEntertainment = 'catentertainment';
  static const String catFood = 'catfood';
  static const String catFreelance = 'catfreelance';
  static const String catGift = 'catgift';
  static const String catGroceries = 'catgroceries';
  static const String catHousing = 'cathousing';
  static const String catInterest = 'catinterest';
  static const String catInvestment = 'catinvestment';
  static const String catMedical = 'catmedical';
  static const String catOther = 'catother';
  static const String catRent = 'catrent';
  static const String catSalary = 'catsalary';
  static const String catSubscription = 'catsubscription';
  static const String catTransport = 'cattransport';
  static const String catUtilities = 'catutilities';
  static const String chartBalanceIndicator = 'chartbalanceindicator';
  static const String chartBarSpending = 'chartbarspending';
  static const String chartBarTemplate = 'chartbartemplate';
  static const String chartChipExpense = 'chartchipexpense';
  static const String chartChipIncome = 'chartchipincome';
  static const String chartCircleBudget = 'chartcirclebudget';
  static const String chartHorizontalBar = 'charthorizontalbar';
  static const String chartPieCategory = 'chartpiecategory';
  static const String chartProgressExpense = 'chartprogressexpense';
  static const String chartProgressIncome = 'chartprogressincome';
  static const String chartStatCardFrame = 'chartstatcardframe';
  static const String chartStatWidgetFrame = 'chartstatwidgetframe';
  static const String chartTopCatIncome = 'charttopcatincome';
  static const String chartWeeklySparkline = 'chartweeklysparkline';
  static const String iconAdd = 'iconadd';
  static const String iconBack = 'iconback';
  static const String iconBooks = 'iconbooks';
  static const String iconCalendar = 'iconcalendar';
  static const String iconCategory = 'iconcategory';
  static const String iconChart = 'iconchart';
  static const String iconDelete = 'icondelete';
  static const String iconExpense = 'iconexpense';
  static const String iconIncome = 'iconincome';
  static const String iconMenu = 'iconmenu';
  static const String iconNotes = 'iconnotes';
  static const String iconPrivacy = 'iconprivacy';
  static const String iconRestaurant = 'iconrestaurant';
  static const String iconSalary = 'iconsalary';
  static const String iconSettings = 'iconsettings';
  static const String iconSync = 'iconsync';
  static const String iconTheme = 'icontheme';
  static const String iconUndo = 'iconundo';
  static const String iconWallet = 'iconwallet';
  static const String illuEmptyAddFirst = 'illuemptyaddfirst';
  static const String illuEmptyCalendar = 'illuemptycalendar';
  static const String illuEmptyFilter = 'illuemptyfilter';
  static const String illuEmptyTransactions = 'illuemptytransactions';
  static const String illuEmptyWallet = 'illuemptywallet';
  static const String illuPlanetIsland = 'illuplanetisland';
  static const String nodeBalance = 'nodebalance';
  static const String nodeExpense = 'nodeexpense';
  static const String nodeIncome = 'nodeincome';
}
