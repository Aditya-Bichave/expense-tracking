// lib/core/theme/app_mode_theme.dart
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Import dart:ui for lerpDouble

// Enums for structured properties
enum LayoutDensity { compact, comfortable, spacious }

enum CardStyle { flat, elevated, floating } // Example

enum ListEntranceAnimation { none, fadeSlide, shimmerSweep }

// Structure for Asset Paths (Makes extension cleaner)
@immutable
class ThemeAssetPaths {
  const ThemeAssetPaths({
    // Common UI elements
    this.fabGlow,
    this.divider,
    this.focusRing,
    this.cardBackground,
    this.mainBackgroundLight,
    this.mainBackgroundDark,

    // Common Icons (map semantic name to path)
    this.commonIcons = const {}, // e.g., {'add': 'path/ic_add.svg'}

    // Category Icons (map category name to path)
    this.categoryIcons =
        const {}, // e.g., {'Groceries': 'path/ic_groceries.svg'}

    // Illustrations (map context to path)
    this.illustrations =
        const {}, // e.g., {'empty_transactions': 'path/empty.svg'}

    // Charts (map type to path)
    this.charts = const {}, // e.g., {'balance_indicator': 'path/balance.svg'}
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

  // Helper method to get a common icon path safely
  String getCommonIcon(String key, {required String defaultPath}) {
    return commonIcons[key] ?? defaultPath;
  }

  // Helper method to get a category icon path safely
  String getCategoryIcon(String key, {required String defaultPath}) {
    // Try exact match first, then case-insensitive
    return categoryIcons[key] ??
        categoryIcons.entries
            .firstWhere((entry) => entry.key.toLowerCase() == key.toLowerCase(),
                orElse: () =>
                    MapEntry(key, defaultPath) // Fallback if not found
                )
            .value;
  }

  // Helper method to get an illustration path safely
  String getIllustration(String key, {required String defaultPath}) {
    return illustrations[key] ?? defaultPath;
  }

  // Helper method to get a chart asset path safely
  String getChartAsset(String key, {required String defaultPath}) {
    return charts[key] ?? defaultPath;
  }
}

@immutable
class AppModeTheme extends ThemeExtension<AppModeTheme> {
  const AppModeTheme({
    required this.modeId, // e.g., 'elemental', 'quantum', 'aether_starfield'
    required this.layoutDensity,
    required this.cardStyle,
    required this.assets, // Use the nested structure
    this.preferDataTableForLists = false,
    this.primaryAnimationDuration = const Duration(milliseconds: 300),
    this.listEntranceAnimation = ListEntranceAnimation.fadeSlide, // Example
    // Add specific custom colors if needed (e.g., glows not in ColorScheme)
    this.incomeGlowColor,
    this.expenseGlowColor,
  });

  final String modeId; // Actually stores the paletteIdentifier for uniqueness
  final LayoutDensity layoutDensity;
  final CardStyle cardStyle;
  final ThemeAssetPaths assets;
  final bool preferDataTableForLists; // Quantum flag
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
    // Lerp colors and durations, switch others abruptly or define specific lerps
    return AppModeTheme(
      modeId: t < 0.5 ? modeId : other.modeId, // Switch identifier abruptly
      layoutDensity: t < 0.5 ? layoutDensity : other.layoutDensity,
      cardStyle: t < 0.5 ? cardStyle : other.cardStyle,
      assets: t < 0.5 ? assets : other.assets, // Asset paths switch abruptly
      preferDataTableForLists:
          t < 0.5 ? preferDataTableForLists : other.preferDataTableForLists,
      // FIX: Manually lerp duration milliseconds
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

  // --- FIXED: Changed from `static var` to `static const String` ---
  // Optional: Define keys for common icons for easier access & consistency
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
  static const String iconExpense = 'expense'; // Quantum specific?
  static const String iconIncome = 'income'; // Quantum specific?
  static const String iconUndo = 'undo'; // Quantum specific?
  static const String iconSync = 'sync'; // Aether specific?
  static const String iconPrivacy = 'privacy'; // Aether specific?
  static const String iconBooks = 'books'; // Aether specific?
  static const String iconRestaurant = 'restaurant'; // Aether specific?
  static const String iconSalary = 'salary'; // Aether specific?
  // --- End Fix ---
}

// Helper extension to get ThemeExtension easily
extension ThemeContextExtension on BuildContext {
  // Provides nullable access to the custom theme extension
  AppModeTheme? get modeTheme => Theme.of(this).extension<AppModeTheme>();
}
