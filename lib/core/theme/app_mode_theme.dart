// lib/core/theme/app_mode_theme.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Import dart:ui for lerpDouble

// Enums for structured properties
enum LayoutDensity { compact, comfortable, spacious }

enum CardStyle { flat, elevated, floating }

enum ListEntranceAnimation { none, fadeSlide, shimmerSweep }

// Structure for Asset Paths
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

  // *** ADDED copyWith Method ***
  ThemeAssetPaths copyWith({
    // Use ValueGetter<String?>? to handle explicit null setting if needed
    // For simplicity, just allowing direct replacement for now.
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
  }) {
    return ThemeAssetPaths(
      fabGlow: fabGlow ?? this.fabGlow,
      divider: divider ?? this.divider,
      focusRing: focusRing ?? this.focusRing,
      cardBackground: cardBackground ?? this.cardBackground,
      mainBackgroundLight: mainBackgroundLight ?? this.mainBackgroundLight,
      mainBackgroundDark: mainBackgroundDark ?? this.mainBackgroundDark,
      // For maps, merge or replace? Replacing is simpler for this context.
      commonIcons: commonIcons ?? this.commonIcons,
      categoryIcons: categoryIcons ?? this.categoryIcons,
      illustrations: illustrations ?? this.illustrations,
      charts: charts ?? this.charts,
    );
  }
  // *** END copyWith Method ***

  String getCommonIcon(String key, {required String defaultPath}) {
    return commonIcons[key] ?? defaultPath;
  }

  String getCategoryIcon(String key, {required String defaultPath}) {
    return categoryIcons[key] ??
        categoryIcons.entries
            .firstWhere((entry) => entry.key.toLowerCase() == key.toLowerCase(),
                orElse: () => MapEntry(key, defaultPath))
            .value;
  }

  String getIllustration(String key, {required String defaultPath}) {
    return illustrations[key] ?? defaultPath;
  }

  String getChartAsset(String key, {required String defaultPath}) {
    return charts[key] ?? defaultPath;
  }
}

@immutable
class AppModeTheme extends ThemeExtension<AppModeTheme> {
  const AppModeTheme({
    required this.modeId,
    required this.layoutDensity,
    required this.cardStyle,
    required this.assets,
    this.preferDataTableForLists = false,
    this.primaryAnimationDuration = const Duration(milliseconds: 300),
    this.listEntranceAnimation = ListEntranceAnimation.fadeSlide,
    this.incomeGlowColor,
    this.expenseGlowColor,
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
    );
  }

  @override
  AppModeTheme lerp(ThemeExtension<AppModeTheme>? other, double t) {
    if (other is! AppModeTheme) {
      return this;
    }
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
    );
  }

  // Icon keys (remain const String)
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
  static const String iconSalary = 'salary';
}

// Helper extension
extension ThemeContextExtension on BuildContext {
  AppModeTheme? get modeTheme => Theme.of(this).extension<AppModeTheme>();
}
