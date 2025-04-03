// lib/core/theme/app_theme.dart
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode
import 'app_mode_theme.dart'; // Import the ThemeExtension class
import 'package:google_fonts/google_fonts.dart';
import 'package:expense_tracker/core/constants/app_constants.dart'; // Import AppConstants

// Import Theme Configs
import 'config/theme_config_interface.dart';
import 'config/elemental_configs.dart';
import 'config/quantum_configs.dart';
import 'config/aether_configs.dart';

// Structure to hold both light and dark theme data
class AppThemeDataPair {
  final ThemeData light;
  final ThemeData dark;
  const AppThemeDataPair({required this.light, required this.dark});
}

class AppTheme {
  // App Name moved to AppConstants
  // static const String appName = "Spend Savvy";

  // --- Palette Identifiers (Used in Settings and for lookups) ---
  // Elemental Palettes
  static const String elementalPalette1 = 'elemental_soft_neutrals'; // Default
  static const String elementalPalette2 = 'elemental_ocean_calm';
  static const String elementalPalette3 = 'elemental_light_airy';
  static const String elementalPalette4 = 'elemental_dark_mode_default';

  // Quantum Palettes
  static const String quantumPalette1 = 'quantum_cyan_dark'; // Default Quantum
  static const String quantumPalette2 = 'quantum_cool_blue';
  static const String quantumPalette3 = 'quantum_warm_red';
  static const String quantumPalette4 = 'quantum_neutral_tech';

  // Aether Palettes
  static const String aetherPalette1 = 'aether_starfield'; // Default Aether
  static const String aetherPalette2 = 'aether_garden';
  static const String aetherPalette3 = 'aether_mystic';
  static const String aetherPalette4 = 'aether_calm_sky';

  // Map palette identifier to display name
  static final Map<String, String> paletteNames = {
    elementalPalette1: 'Soft Neutrals',
    elementalPalette2: 'Ocean Calm',
    elementalPalette3: 'Light & Airy',
    elementalPalette4: 'Default Dark',
    quantumPalette1: 'Cyan Tech',
    quantumPalette2: 'Cool Blue',
    quantumPalette3: 'Warm Red',
    quantumPalette4: 'Neutral Tech',
    aetherPalette1: 'Starfield',
    aetherPalette2: 'Garden',
    aetherPalette3: 'Mystic',
    aetherPalette4: 'Calm Sky',
  };

  // Map UI mode enum to display names
  static final Map<UIMode, String> uiModeNames = {
    UIMode.elemental: 'Elemental',
    UIMode.quantum: 'Quantum',
    UIMode.aether: 'Aether',
  };

  // Central factory method - SIMPLIFIED
  static AppThemeDataPair buildTheme(UIMode mode, String paletteIdentifier) {
    // 1. Get the configuration object for the mode and palette
    final IThemePaletteConfig config =
        _getConfigForMode(mode, paletteIdentifier);

    // 2. Get the appropriate base theme builder
    final baseThemeBuilder = _getBaseThemeBuilder(mode);

    // 3. Build the custom theme extension
    final lightModeTheme = _buildModeThemeExtension(config, Brightness.light);
    final darkModeTheme = _buildModeThemeExtension(config, Brightness.dark);

    // 4. Build the final ThemeData objects using the config and builder
    final lightTheme =
        baseThemeBuilder(config.lightColorScheme, lightModeTheme);
    final darkTheme = baseThemeBuilder(config.darkColorScheme, darkModeTheme);

    return AppThemeDataPair(light: lightTheme, dark: darkTheme);
  }

  // --- Helper to get Config ---
  static IThemePaletteConfig _getConfigForMode(UIMode mode, String paletteId) {
    switch (mode) {
      case UIMode.elemental:
        return ElementalConfigs.getConfig(paletteId);
      case UIMode.quantum:
        return QuantumConfigs.getConfig(paletteId);
      case UIMode.aether:
        return AetherConfigs.getConfig(paletteId);
    }
  }

  // --- Helper to get Base Theme Builder ---
  static Function(ColorScheme, AppModeTheme) _getBaseThemeBuilder(UIMode mode) {
    switch (mode) {
      case UIMode.quantum:
        return _buildQuantumBaseThemeData;
      case UIMode.aether:
        return _buildAetherBaseThemeData;
      case UIMode.elemental:
      default:
        return _buildElementalBaseThemeData;
    }
  }

  // --- Helper to build AppModeTheme from Config ---
  static AppModeTheme _buildModeThemeExtension(
      IThemePaletteConfig config, Brightness brightness) {
    final assets =
        brightness == Brightness.light ? config.lightAssets : config.darkAssets;
    final incomeGlow = brightness == Brightness.light
        ? config.incomeGlowColorLight
        : config.incomeGlowColorDark;
    final expenseGlow = brightness == Brightness.light
        ? config.expenseGlowColorLight
        : config.expenseGlowColorDark;

    return AppModeTheme(
      // modeId: paletteIdentifier, // Mode ID isn't directly in config, maybe add it? For now, it's implicit.
      modeId:
          '', // Or retrieve from somewhere else if needed by AppModeTheme consumers
      layoutDensity: config.layoutDensity,
      cardStyle: config.cardStyle,
      assets: assets,
      preferDataTableForLists: config.preferDataTableForLists,
      primaryAnimationDuration: config.primaryAnimationDuration,
      listEntranceAnimation: config.listEntranceAnimation,
      incomeGlowColor: incomeGlow,
      expenseGlowColor: expenseGlow,
    );
  }

  // --- Base Theme Builders ( Largely unchanged, just consume ColorScheme/AppModeTheme) ---

  static ThemeData _buildElementalBaseThemeData(
      ColorScheme colorScheme, AppModeTheme modeTheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.light
        ? GoogleFonts.interTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    // (Keep the rest of this function as it was in your previous version)
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: baseTextTheme.copyWith(
        titleLarge:
            baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        titleMedium:
            baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
        bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 16),
        bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 14),
        labelLarge: baseTextTheme.labelLarge
            ?.copyWith(fontWeight: FontWeight.w500), // For buttons
      ),
      visualDensity: VisualDensity.standard,
      cardTheme: CardTheme(
          elevation: modeTheme.cardStyle == CardStyle.elevated ? 1.5 : 0,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: colorScheme.surfaceContainer),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        minVerticalPadding: 12,
        horizontalTitleGap: 12,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: baseTextTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        textStyle: baseTextTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
      )),
      appBarTheme: AppBarTheme(
        elevation: 0.5,
        centerTitle: true,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        scrolledUnderElevation: 1.0,
        titleTextStyle: baseTextTheme.titleLarge,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surfaceContainer,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.7),
        elevation: 2,
        selectedLabelStyle:
            baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500),
        unselectedLabelStyle: baseTextTheme.labelSmall,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 0.8,
        space: 1,
      ),
      extensions: <ThemeExtension<dynamic>>[
        modeTheme,
      ],
    );
  }

  static ThemeData _buildQuantumBaseThemeData(
      ColorScheme colorScheme, AppModeTheme modeTheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.light
        ? GoogleFonts.robotoMonoTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.robotoMonoTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseTextTheme.copyWith(
      // (Keep textTheme modifications as before)
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 13),
      titleMedium: baseTextTheme.titleMedium
          ?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 11),
      displayLarge: baseTextTheme.displayLarge
          ?.copyWith(fontSize: 26, fontWeight: FontWeight.w600),
      headlineSmall: baseTextTheme.headlineSmall
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
    );

    // (Keep the rest of this function as it was in your previous version)
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.compact,
      cardTheme: CardTheme(
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: colorScheme.outlineVariant, width: 0.8),
        ),
        color: colorScheme.surface,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        dense: true,
        minVerticalPadding: 8,
        horizontalTitleGap: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
          borderRadius: BorderRadius.circular(6),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        isDense: true,
        floatingLabelBehavior: FloatingLabelBehavior.always,
      ),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
        elevation: 0,
      )),
      appBarTheme: AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          titleTextStyle:
              textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500)),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          elevation: 0,
          highlightElevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surface,
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.6),
        elevation: 0,
        selectedLabelStyle: textTheme.labelSmall,
        unselectedLabelStyle: textTheme.labelSmall,
        selectedIconTheme: const IconThemeData(size: 20),
        unselectedIconTheme: const IconThemeData(size: 20),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      dataTableTheme: DataTableThemeData(
        columnSpacing: 12,
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        headingTextStyle: textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600, color: colorScheme.onSurfaceVariant),
        dataTextStyle:
            textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
        dividerThickness: 0.8,
        dataRowColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
          if (states.contains(MaterialState.selected)) {
            return colorScheme.primaryContainer.withOpacity(0.2);
          }
          return null;
        }),
      ),
      extensions: <ThemeExtension<dynamic>>[
        modeTheme,
      ],
    );
  }

  static ThemeData _buildAetherBaseThemeData(
      ColorScheme colorScheme, AppModeTheme modeTheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.light
        ? GoogleFonts.quicksandTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.quicksandTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseTextTheme.copyWith(
      // (Keep textTheme modifications as before)
      titleLarge: baseTextTheme.titleLarge
          ?.copyWith(fontWeight: FontWeight.w500, letterSpacing: 0.5),
      titleMedium:
          baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontSize: 17, height: 1.4),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 15),
      labelLarge:
          baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
      displayLarge: baseTextTheme.displayLarge
          ?.copyWith(fontWeight: FontWeight.w500, fontSize: 30),
    );

    // (Keep the rest of this function as it was in your previous version)
    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: colorScheme.background,
      cardTheme: CardTheme(
        elevation: modeTheme.cardStyle == CardStyle.floating ? 6 : 3,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        color: colorScheme.surfaceVariant.withOpacity(0.85),
        clipBehavior: Clip.antiAlias,
      ),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        minVerticalPadding: 16,
        horizontalTitleGap: 16,
      ),
      inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: colorScheme.surfaceVariant.withOpacity(0.7),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colorScheme.primary, width: 1.5)),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          floatingLabelStyle: TextStyle(color: colorScheme.primary)),
      textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      )),
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        textStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
      )),
      appBarTheme: AppBarTheme(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onBackground,
        titleTextStyle:
            textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.tertiaryContainer,
        foregroundColor: colorScheme.onTertiaryContainer,
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor: colorScheme.surfaceVariant.withOpacity(0.9),
        selectedItemColor: colorScheme.primary,
        unselectedItemColor: colorScheme.onSurfaceVariant.withOpacity(0.8),
        elevation: 0,
        selectedLabelStyle:
            textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        unselectedLabelStyle: textTheme.labelMedium,
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.primary.withOpacity(0.3),
        thickness: 1,
        space: 24,
        indent: 20,
        endIndent: 20,
      ),
      extensions: <ThemeExtension<dynamic>>[
        modeTheme,
      ],
    );
  }

  // REMOVED: _getColorSchemeForIdentifier (now handled by config classes)
  // REMOVED: _getModeThemeExtension (now handled by helper + config classes)
  // REMOVED: _getElementalAssets, _getQuantumAssets, _getAetherAssets (now in config classes)
} // End of AppTheme class

// Helper Extension for String Capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
