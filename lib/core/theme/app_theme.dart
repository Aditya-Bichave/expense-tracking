// lib/core/theme/app_theme.dart
// ignore_for_file: deprecated_member_use, unused_local_variable

import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode
import 'app_mode_theme.dart'; // Import the new extension class
import 'package:google_fonts/google_fonts.dart'; // Example font import

// Structure to hold both light and dark theme data
class AppThemeDataPair {
  final ThemeData light;
  final ThemeData dark;

  const AppThemeDataPair({required this.light, required this.dark});
}

class AppTheme {
  static const String appName = "Spend Savvy";

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

  // Aether Palettes (Map directly to sub-themes for simplicity now)
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

  // Central factory method
  static AppThemeDataPair buildTheme(UIMode mode, String paletteIdentifier) {
    // 1. Determine Base Theme Builder based on UI Mode
    Function(ColorScheme, AppModeTheme) baseThemeBuilder;
    switch (mode) {
      case UIMode.quantum:
        baseThemeBuilder = _buildQuantumBaseThemeData;
        break;
      case UIMode.aether:
        baseThemeBuilder = _buildAetherBaseThemeData;
        break;
      case UIMode.elemental:
      default: // Fallback to elemental
        baseThemeBuilder = _buildElementalBaseThemeData;
        break;
    }

    // 2. Get Color Schemes for the selected Palette (Light & Dark)
    final lightColorScheme =
        _getColorSchemeForIdentifier(paletteIdentifier, Brightness.light);
    final darkColorScheme =
        _getColorSchemeForIdentifier(paletteIdentifier, Brightness.dark);

    // 3. Get the Custom Theme Extension Data for the Mode + Palette
    final lightModeThemeExtension =
        _getModeThemeExtension(mode, paletteIdentifier, Brightness.light);
    final darkModeThemeExtension =
        _getModeThemeExtension(mode, paletteIdentifier, Brightness.dark);

    // 4. Build the final ThemeData objects
    final lightTheme =
        baseThemeBuilder(lightColorScheme, lightModeThemeExtension);
    final darkTheme = baseThemeBuilder(darkColorScheme, darkModeThemeExtension);

    return AppThemeDataPair(light: lightTheme, dark: darkTheme);
  }

  // --- Base Theme Builders (Define core structure per mode) ---

  static ThemeData _buildElementalBaseThemeData(
      ColorScheme colorScheme, AppModeTheme modeTheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.light
        ? GoogleFonts.interTextTheme(ThemeData.light().textTheme)
        : GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

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
      visualDensity: VisualDensity
          .standard, // Use standard instead of comfortablePlatformDensity
      cardTheme: CardTheme(
          elevation: modeTheme.cardStyle == CardStyle.elevated
              ? 1.5
              : 0, // Subtle elevation
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          color: colorScheme.surfaceContainer // Slightly different surface
          ),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)), // Slightly squarish
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            colorScheme.surfaceContainer, // Match card/appbar surface?
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
        space: 1, // Minimal space for dividers used in lists etc.
      ),
      extensions: <ThemeExtension<dynamic>>[
        modeTheme, // Attach the extension
      ],
    );
  }

  static ThemeData _buildQuantumBaseThemeData(
      ColorScheme colorScheme, AppModeTheme modeTheme) {
    final baseTextTheme = colorScheme.brightness == Brightness.light
        ? GoogleFonts.robotoMonoTextTheme(
            ThemeData.light().textTheme) // Monospace
        : GoogleFonts.robotoMonoTextTheme(ThemeData.dark().textTheme);

    final textTheme = baseTextTheme.copyWith(
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontSize: 13),
      titleMedium: baseTextTheme.titleMedium
          ?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontSize: 11),
      displayLarge: baseTextTheme.displayLarge
          ?.copyWith(fontSize: 26, fontWeight: FontWeight.w600),
      headlineSmall: baseTextTheme.headlineSmall
          ?.copyWith(fontSize: 18, fontWeight: FontWeight.w500),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity.compact, // Quantum dense
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
        // Add specific DataTable theme for Quantum
        columnSpacing: 12, headingRowHeight: 36, dataRowMinHeight: 36,
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
          return null; // Use default value for other states and odd/even rows.
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

    return ThemeData(
      useMaterial3: true,
      brightness: colorScheme.brightness,
      colorScheme: colorScheme,
      textTheme: textTheme,
      visualDensity: VisualDensity
          .standard, // Aether might be spacious, but start standard
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

  // --- Color Scheme Factory ---
  static ColorScheme _getColorSchemeForIdentifier(
      String identifier, Brightness brightness) {
    bool isDark = brightness == Brightness.dark;

    // Define seed colors for palettes where applicable
    Color seedColor;
    // Use specific colors for high-contrast or very distinct themes like Quantum/Aether
    switch (identifier) {
      // Elemental - Use Seed
      case elementalPalette1:
        seedColor = const Color(0xFF3A7BD5);
        break;
      case elementalPalette2:
        seedColor = const Color(0xFF039BE5);
        break;
      case elementalPalette3:
        seedColor = const Color(0xFF9C27B0);
        break;
      case elementalPalette4:
        // Force dark for this specific Elemental variant
        return ColorScheme.fromSeed(
            seedColor: const Color(0xFFBB86FC), brightness: Brightness.dark);

      // Quantum - Use Specific Colors
      case quantumPalette1:
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFF00BCD4),
                secondary: Color(0xFF80DEEA),
                tertiary: Color(0xFF00E676),
                background: Color(0xFF121212),
                surface: Color(0xFF1E1E1E),
                surfaceContainer: Color(0xFF242424),
                error: Color(0xFFFF5252),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Colors.white,
                onSurface: Colors.white,
                onSurfaceVariant: Color(0xFFAAAAAA),
                onError: Colors.black,
                outline: Color(0xFF444444),
                outlineVariant: Color(0xFF333333),
                primaryContainer: Color(0xFF005662),
                onPrimaryContainer: Color(0xFF80DEEA),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFF00838F),
                secondary: Color(0xFF00ACC1),
                tertiary: Color(0xFF00A74E),
                background: Color(0xFFFAFAFA),
                surface: Color(0xFFFFFFFF),
                surfaceContainer: Color(0xFFF5F5F5),
                error: Color(0xFFD32F2F),
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF666666),
                onError: Colors.white,
                outline: Color(0xFFBDBDBD),
                outlineVariant: Color(0xFFCCCCCC),
                primaryContainer: Color(0xFFB2EBF2),
                onPrimaryContainer: Color(0xFF006064),
                brightness: Brightness.light);
      case quantumPalette2:
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFF3D5AFE),
                secondary: Color(0xFF90CAF9),
                tertiary: Color(0xFF00E676),
                background: Color(0xFF0F1C2E),
                surface: Color(0xFF1E2D3C),
                surfaceContainer: Color(0xFF283A4C),
                error: Color(0xFFFF4081),
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onBackground: Colors.white,
                onSurface: Colors.white,
                onSurfaceVariant: Color(0xFFB0BEC5),
                onError: Colors.black,
                outline: Color(0xFF445A70),
                outlineVariant: Color(0xFF334659),
                primaryContainer: Color(0xFF1A237E),
                onPrimaryContainer: Color(0xFFC5CAE9),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFF304FFE),
                secondary: Color(0xFF448AFF),
                tertiary: Color(0xFF00A74E),
                background: Color(0xFFF0F4F8),
                surface: Color(0xFFFFFFFF),
                surfaceContainer: Color(0xFFE3F2FD),
                error: Color(0xFFF50057),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF607D8B),
                onError: Colors.white,
                outline: Color(0xFFB0BEC5),
                outlineVariant: Color(0xFFCFD8DC),
                primaryContainer: Color(0xFFC5CAE9),
                onPrimaryContainer: Color(0xFF1A237E),
                brightness: Brightness.light);
      case quantumPalette3: // Warm Red
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFFEF5350),
                secondary: Color(0xFFFF8A80),
                tertiary: Color(0xFF66BB6A),
                background: Color(0xFF1A0000),
                surface: Color(0xFF330000),
                surfaceContainer: Color(0xFF4D0000),
                error: Color(0xFFFF1744),
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onBackground: Colors.white,
                onSurface: Colors.white,
                onSurfaceVariant: Color(0xFFEF9A9A),
                onError: Colors.white,
                outline: Color(0xFF663333),
                outlineVariant: Color(0xFF552222),
                primaryContainer: Color(0xFFB71C1C),
                onPrimaryContainer: Color(0xFFFFCDD2),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFFD32F2F),
                secondary: Color(0xFFE57373),
                tertiary: Color(0xFF4CAF50),
                background: Color(0xFFFFF8F8),
                surface: Color(0xFFFFFFFF),
                surfaceContainer: Color(0xFFFFEBEE),
                error: Color(0xFFC62828),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF757575),
                onError: Colors.white,
                outline: Color(0xFFE0E0E0),
                outlineVariant: Color(0xFFF5F5F5),
                primaryContainer: Color(0xFFFFCDD2),
                onPrimaryContainer: Color(0xFFB71C1C),
                brightness: Brightness.light);
      case quantumPalette4: // Neutral Tech
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFF9FA8DA),
                secondary: Color(0xFFC5CAE9),
                tertiary: Color(0xFF81C784),
                background: Color(0xFF202124),
                surface: Color(0xFF2A2B2E),
                surfaceContainer: Color(0xFF333438),
                error: Color(0xFFE57373),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Color(0xFFE8EAED),
                onSurface: Color(0xFFE8EAED),
                onSurfaceVariant: Color(0xFFB0BEC5),
                onError: Colors.black,
                outline: Color(0xFF5F6368),
                outlineVariant: Color(0xFF4A4B4F),
                primaryContainer: Color(0xFF3F51B5),
                onPrimaryContainer: Color(0xFFC5CAE9),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFF5C6BC0),
                secondary: Color(0xFF7986CB),
                tertiary: Color(0xFF66BB6A),
                background: Color(0xFFF1F3F4),
                surface: Color(0xFFFFFFFF),
                surfaceContainer: Color(0xFFE8EAED),
                error: Color(0xFFE53935),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF5F6368),
                onError: Colors.white,
                outline: Color(0xFFDADCE0),
                outlineVariant: Color(0xFFE8EAED),
                primaryContainer: Color(0xFFC5CAE9),
                onPrimaryContainer: Color(0xFF3F51B5),
                brightness: Brightness.light);

      // Aether - Use Specific Colors
      case aetherPalette1: // Starfield
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFFA18BFF),
                secondary: Color(0xFFB39DDB),
                tertiary: Color(0xFF00FFAA),
                background: Color(0xFF0F0D2E),
                surface: Color(0xFF1C183F),
                surfaceVariant: Color(0xFF2A2450),
                error: Color(0xFFFF6B81),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Color(0xFFCCCCDD),
                onSurface: Colors.white,
                onSurfaceVariant: Color(0xAA9999AA),
                onError: Colors.black,
                primaryContainer: Color(0xFF512DA8),
                onPrimaryContainer: Color(0xFFD1C4E9),
                tertiaryContainer: Color(0xFF00503B),
                onTertiaryContainer: Color(0xFF50FFC1),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFF7C4DFF),
                secondary: Color(0xFF9575CD),
                tertiary: Color(0xFF00BFA5),
                background: Color(0xFFE8EAF6),
                surface: Color(0xFFFFFFFF),
                surfaceVariant: Color(0xFFF0F0F8),
                error: Color(0xFFEF5350),
                onPrimary: Colors.white,
                onSecondary: Colors.white,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF7986CB),
                onError: Colors.white,
                primaryContainer: Color(0xFFD1C4E9),
                onPrimaryContainer: Color(0xFF512DA8),
                tertiaryContainer: Color(0xFF78FFE1),
                onTertiaryContainer: Color(0xFF003D31),
                brightness: Brightness.light);
      case aetherPalette2: // Garden
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFF88FFC2),
                secondary: Color(0xFFA5D6A7),
                tertiary: Color(0xFFFFD180),
                background: Color(0xFF101F1C),
                surface: Color(0xFF1B2C27),
                surfaceVariant: Color(0xFF2C3E39),
                error: Color(0xFFFF7043),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Color(0xFFFAFAFA),
                onSurface: Colors.white,
                onSurfaceVariant: Color(0xFFA5D6A7),
                onError: Colors.black,
                primaryContainer: Color(0xFF00695C),
                onPrimaryContainer: Color(0xFFA7FFEB),
                tertiaryContainer: Color(0xFF5F4000),
                onTertiaryContainer: Color(0xFFFFE082),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFF00BFA5),
                secondary: Color(0xFF69F0AE),
                tertiary: Color(0xFFFFAB40),
                background: Color(0xFFE8F5E9),
                surface: Color(0xFFFFFFFF),
                surfaceVariant: Color(0xFFF0FAF1),
                error: Color(0xFFFF6E40),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF4CAF50),
                onError: Colors.black,
                primaryContainer: Color(0xFFA7FFEB),
                onPrimaryContainer: Color(0xFF00695C),
                tertiaryContainer: Color(0xFFFFD180),
                onTertiaryContainer: Color(0xFF5F4000),
                brightness: Brightness.light);
      case aetherPalette3: // Mystic
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFFD0B3FF),
                secondary: Color(0xFFE1BEE7),
                tertiary: Color(0xFF00E676),
                background: Color(0xFF1B0033),
                surface: Color(0xFF29004D),
                surfaceVariant: Color(0xFF3C006A),
                error: Color(0xFFFF3D00),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Color(0xFFF3E5F5),
                onSurface: Colors.white,
                onSurfaceVariant: Color(0xFFCE93D8),
                onError: Colors.white,
                primaryContainer: Color(0xFF6A1B9A),
                onPrimaryContainer: Color(0xFFE1BEE7),
                tertiaryContainer: Color(0xFF005129),
                onTertiaryContainer: Color(0xFF3EFF99),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFFAB47BC),
                secondary: Color(0xFFCE93D8),
                tertiary: Color(0xFF00BFA5),
                background: Color(0xFFF3E5F5),
                surface: Color(0xFFFFFFFF),
                surfaceVariant: Color(0xFFF8F0FC),
                error: Color(0xFFDD2C00),
                onPrimary: Colors.white,
                onSecondary: Colors.black,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF8E24AA),
                onError: Colors.white,
                primaryContainer: Color(0xFFE1BEE7),
                onPrimaryContainer: Color(0xFF6A1B9A),
                tertiaryContainer: Color(0xFF00E676),
                onTertiaryContainer: Color(0xFF003E20),
                brightness: Brightness.light);
      case aetherPalette4: // Calm Sky
        return isDark
            ? const ColorScheme.dark(
                primary: Color(0xFF89CFF0),
                secondary: Color(0xFFB0E0E6),
                tertiary: Color(0xFF00DFA2),
                background: Color(0xFF121F2E),
                surface: Color(0xFF1C2E45),
                surfaceVariant: Color(0xFF2C3E50),
                error: Color(0xFFF08080),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Color(0xFFECEFF1),
                onSurface: Colors.white,
                onSurfaceVariant: Color(0xFF90A4AE),
                onError: Colors.black,
                primaryContainer: Color(0xFF0277BD),
                onPrimaryContainer: Color(0xFFB3E5FC),
                tertiaryContainer: Color(0xFF00513B),
                onTertiaryContainer: Color(0xFF34FFC1),
                brightness: Brightness.dark)
            : const ColorScheme.light(
                primary: Color(0xFF4FC3F7),
                secondary: Color(0xFF81D4FA),
                tertiary: Color(0xFF26A69A),
                background: Color(0xFFE3F2FD),
                surface: Color(0xFFFFFFFF),
                surfaceVariant: Color(0xFFF0F7FC),
                error: Color(0xFFE57373),
                onPrimary: Colors.black,
                onSecondary: Colors.black,
                onBackground: Colors.black,
                onSurface: Colors.black,
                onSurfaceVariant: Color(0xFF546E7A),
                onError: Colors.white,
                primaryContainer: Color(0xFFB3E5FC),
                onPrimaryContainer: Color(0xFF0277BD),
                tertiaryContainer: Color(0xFF78F8D6),
                onTertiaryContainer: Color(0xFF00382A),
                brightness: Brightness.light);

      // Default fallback (Elemental Palette 1)
      default:
        seedColor = const Color(0xFF3A7BD5);
        return ColorScheme.fromSeed(
            seedColor: seedColor, brightness: brightness);
    }

    // This part is only reached for Elemental themes using seed color if not default
    return ColorScheme.fromSeed(seedColor: seedColor, brightness: brightness);
  }

  // --- Custom Theme Extension Factory ---
  static AppModeTheme _getModeThemeExtension(
      UIMode mode, String paletteIdentifier, Brightness brightness) {
    // Default values
    LayoutDensity density = LayoutDensity.comfortable;
    CardStyle cardStyle = CardStyle.elevated;
    bool preferTables = false;
    ListEntranceAnimation listAnim = ListEntranceAnimation.fadeSlide;
    Color? incomeGlow = (brightness == Brightness.dark
            ? Colors.greenAccent[100]
            : Colors.green[700])
        ?.withOpacity(0.4);
    Color? expenseGlow = (brightness == Brightness.dark
            ? Colors.redAccent[100]
            : Colors.red[700])
        ?.withOpacity(0.4);
    ThemeAssetPaths assets = _getElementalAssets(paletteIdentifier); // Default

    // Mode Specific Overrides
    if (mode == UIMode.quantum) {
      density = LayoutDensity.compact;
      cardStyle = CardStyle.flat;
      preferTables = true;
      listAnim = ListEntranceAnimation.none;
      incomeGlow = null;
      expenseGlow = null;
      assets = _getQuantumAssets(paletteIdentifier);
    } else if (mode == UIMode.aether) {
      density = LayoutDensity.spacious;
      cardStyle = CardStyle.floating;
      listAnim = ListEntranceAnimation.shimmerSweep;
      assets = _getAetherAssets(paletteIdentifier);
      // Set Aether glow colors based on palette
      switch (paletteIdentifier) {
        case aetherPalette1:
          incomeGlow = const Color(0xAA00FFAA);
          expenseGlow = const Color(0xAAFF6B81);
          break;
        case aetherPalette2:
          incomeGlow = const Color(0xAA00E676);
          expenseGlow = const Color(0xAAFF7043);
          break;
        case aetherPalette3:
          incomeGlow = const Color(0xAA00E676);
          expenseGlow = const Color(0xAAFF3D00);
          break;
        case aetherPalette4:
          incomeGlow = const Color(0xAA00DFA2);
          expenseGlow = const Color(0xAAF44336);
          break;
      }
    } else {
      // Elemental (already default)
      assets = _getElementalAssets(paletteIdentifier);
    }

    return AppModeTheme(
      modeId: paletteIdentifier,
      layoutDensity: density,
      cardStyle: cardStyle,
      assets: assets,
      preferDataTableForLists: preferTables,
      listEntranceAnimation: listAnim,
      incomeGlowColor: incomeGlow,
      expenseGlowColor: expenseGlow,
      primaryAnimationDuration: (mode == UIMode.quantum)
          ? const Duration(milliseconds: 150)
          : (mode == UIMode.aether)
              ? const Duration(milliseconds: 450)
              : const Duration(milliseconds: 300),
    );
  }

  // --- Asset Loading Helpers (Populate with actual paths) ---

  static ThemeAssetPaths _getElementalAssets(String paletteId) {
    String commonIconPath = 'assets/elemental/icons/common/';
    String catIconPath = 'assets/elemental/icons/categories/';
    String illustrationPath = 'assets/elemental/illustrations/';
    String bgPath = 'assets/elemental/backgrounds/';
    String chartPath = 'assets/elemental/charts/';
    String decorativePath = 'assets/elemental/decorative/';
    // Example: Check if a palette-specific FAB glow exists
    // Construct path based on convention
    String paletteNum = paletteId.split('_').last; // e.g., palette1, palette2
    String fabGlowPath =
        'assets/elemental/theme_$paletteNum/fab_${paletteNum}_glow.svg';
    // A real implementation would check File(fabGlowPath).exists() or have a predefined map
    // For simplicity, assume they exist for now if the ID matches the convention
    bool paletteFabExists = [
      elementalPalette1,
      elementalPalette2,
      elementalPalette3,
      elementalPalette4
    ].contains(paletteId); // Crude check

    return ThemeAssetPaths(
        mainBackgroundLight: '${bgPath}bg_elemental_light.svg',
        mainBackgroundDark: '${bgPath}bg_elemental_dark.svg',
        cardBackground: '${bgPath}bg_card_surface.svg',
        fabGlow: paletteFabExists
            ? fabGlowPath
            : null, // Use palette specific or null
        divider: '${decorativePath}divider_line.svg',
        focusRing: '${decorativePath}focus_ring.svg',
        commonIcons: {
          AppModeTheme.iconAdd: '${commonIconPath}ic_add.svg',
          AppModeTheme.iconSettings: '${commonIconPath}ic_settings.svg',
          AppModeTheme.iconBack: '${commonIconPath}ic_back.svg',
          AppModeTheme.iconCalendar: '${commonIconPath}ic_calendar.svg',
          AppModeTheme.iconCategory: '${commonIconPath}ic_category.svg',
          AppModeTheme.iconChart: '${commonIconPath}ic_chart.svg',
          AppModeTheme.iconDelete: '${commonIconPath}ic_delete.svg',
          AppModeTheme.iconMenu: '${commonIconPath}ic_menu.svg',
          AppModeTheme.iconNotes: '${commonIconPath}ic_notes.svg',
          AppModeTheme.iconTheme: '${commonIconPath}ic_theme.svg',
          AppModeTheme.iconWallet: '${commonIconPath}ic_wallet.svg',
        },
        categoryIcons: {
          // Use lowercase keys for easier matching
          'food': '${catIconPath}ic_food.svg',
          'groceries': '${catIconPath}ic_groceries.svg',
          'transport': '${catIconPath}ic_transport.svg',
          'entertainment': '${catIconPath}ic_entertainment.svg',
          'medical': '${catIconPath}ic_medical.svg',
          'salary': '${catIconPath}ic_salary.svg',
          'subscription': '${catIconPath}ic_subscription.svg',
          'utilities': '${catIconPath}ic_subscription.svg', // Placeholder
          'housing': '${catIconPath}ic_food.svg', // Placeholder
          'bonus': '${catIconPath}ic_salary.svg',
          'freelance': '${catIconPath}ic_salary.svg',
          'gift': '${catIconPath}ic_salary.svg',
          'interest': '${catIconPath}ic_salary.svg',
          'other': '${commonIconPath}ic_category.svg',
          // Add account types if using the same map
          'bank': '${commonIconPath}ic_wallet.svg', // Example
          'cash': '${commonIconPath}ic_wallet.svg', // Example
          'crypto': '${commonIconPath}ic_wallet.svg', // Example
          'investment': '${commonIconPath}ic_chart.svg', // Example
        },
        illustrations: {
          'empty_transactions': '${illustrationPath}empty_add_transaction.svg',
          'empty_wallet': '${illustrationPath}empty_wallet.svg',
          'empty_calendar': '${illustrationPath}empty_calendar.svg',
          'empty_filter':
              '${illustrationPath}empty_calendar.svg', // Example for filter empty state
        },
        charts: {
          'bar_spending': '${chartPath}bar_chart_spending.svg',
          'chip_income': '${chartPath}chip_income.svg',
          'chip_expense': '${chartPath}chip_expense.svg',
          'budget_usage_circle': '${chartPath}circle_budget_usage.svg',
          'stat_card_frame': '${chartPath}stat_card_frame.svg',
        });
  }

  static ThemeAssetPaths _getQuantumAssets(String paletteId) {
    String commonIconPath = 'assets/quantum/icons/common/';
    String catIconPath = 'assets/quantum/icons/categories/';
    String illustrationPath = 'assets/quantum/illustrations/';
    String bgPath = 'assets/quantum/backgrounds/';
    String chartPath = 'assets/quantum/charts/';
    // Assuming paletteId is like 'quantum_palette1', 'quantum_palette2' etc.
    String paletteNum =
        paletteId.replaceFirst('quantum_', 'theme_'); // e.g., "theme_palette1"
    String paletteSpecificPath = 'assets/quantum/$paletteNum/';

    // Check if palette specific FAB glow exists (crude check)
    bool paletteFabExists = [
      quantumPalette1,
      quantumPalette2,
      quantumPalette3,
      quantumPalette4
    ].contains(paletteId);

    String fabGlowPath =
        '${paletteSpecificPath}fab_${paletteNum.split('_').last}_glow.svg';

    return ThemeAssetPaths(
        mainBackgroundDark: '${bgPath}bg_quantum_dark.svg',
        cardBackground: '${bgPath}bg_card_dark.svg',
        fabGlow:
            paletteFabExists ? fabGlowPath : null, // Construct path carefully
        divider: null, // Quantum doesn't use the SVG divider
        focusRing: null, // Quantum doesn't use the SVG focus ring
        commonIcons: {
          AppModeTheme.iconAdd: '${commonIconPath}ic_add.svg',
          AppModeTheme.iconSettings: '${commonIconPath}ic_settings.svg',
          AppModeTheme.iconBack: '${commonIconPath}ic_back.svg',
          AppModeTheme.iconCalendar: '${commonIconPath}ic_calendar.svg',
          AppModeTheme.iconCategory: '${commonIconPath}ic_category.svg',
          AppModeTheme.iconChart: '${commonIconPath}ic_chart.svg',
          AppModeTheme.iconDelete: '${commonIconPath}ic_delete.svg',
          AppModeTheme.iconMenu: '${commonIconPath}ic_menu.svg',
          AppModeTheme.iconExpense: '${commonIconPath}ic_expense.svg',
          AppModeTheme.iconIncome: '${commonIconPath}ic_income.svg',
          AppModeTheme.iconUndo: '${commonIconPath}ic_undo.svg',
          AppModeTheme.iconNotes:
              '${commonIconPath}ic_category.svg', // Fallback?
          AppModeTheme.iconTheme:
              '${commonIconPath}ic_settings.svg', // Fallback?
          AppModeTheme.iconWallet:
              '${commonIconPath}ic_category.svg', // Fallback?
        },
        categoryIcons: {
          'groceries': '${catIconPath}ic_groceries.svg',
          'rent': '${catIconPath}ic_rent.svg',
          'utilities': '${catIconPath}ic_utilities.svg',
          'freelance': '${catIconPath}ic_freelance.svg',
          'food': '${catIconPath}ic_groceries.svg',
          'transport': '${commonIconPath}ic_expense.svg',
          'entertainment': '${commonIconPath}ic_expense.svg',
          'medical': '${commonIconPath}ic_expense.svg',
          'salary': '${commonIconPath}ic_income.svg',
          'subscription': '${catIconPath}ic_utilities.svg',
          'housing': '${catIconPath}ic_rent.svg',
          'bonus': '${commonIconPath}ic_income.svg',
          'gift': '${commonIconPath}ic_income.svg',
          'interest': '${commonIconPath}ic_income.svg',
          'other': '${commonIconPath}ic_category.svg',
          // Account types
          'bank': '${commonIconPath}ic_category.svg',
          'cash': '${commonIconPath}ic_category.svg',
          'crypto': '${commonIconPath}ic_category.svg',
          'investment': '${commonIconPath}ic_chart.svg',
        },
        illustrations: {
          'empty_transactions': '${illustrationPath}empty_transactions.svg',
          'empty_dark_sky': '${illustrationPath}empty_dark_sky.svg',
          'empty_add_first': '${illustrationPath}empty_add_first.svg',
          'empty_filter':
              '${illustrationPath}empty_transactions.svg', // Example
        },
        charts: {
          'bar_generic': '${chartPath}bar_chart_template.svg',
          'progress_income': '${chartPath}horizontal_progress_income.svg',
          'progress_expense': '${chartPath}horizontal_progress_expense.svg',
          'pie_category': '${chartPath}pie_category_distribution.svg',
          'stat_widget_frame': '${chartPath}stat_widget_frame.svg',
        });
  }

  static ThemeAssetPaths _getAetherAssets(String paletteId) {
    String commonIconPath = 'assets/aether/icons/common/';
    String illustrationPath = 'assets/aether/illustrations/';
    String bgPath = 'assets/aether/backgrounds/';
    String chartPath = 'assets/aether/charts/';
    // Assuming paletteId is like 'aether_starfield', 'aether_garden'
    String paletteSuffix =
        paletteId.split('_').last; // e.g., "starfield", "garden"
    // Construct palette specific path, e.g., assets/aether/palette1_starfield/
    String paletteSubFolderName = 'palette${[
          'starfield',
          'garden',
          'mystic',
          'calm_sky'
        ].indexOf(paletteSuffix) + 1}_$paletteSuffix';
    if (!['starfield', 'garden', 'mystic', 'calm_sky']
        .contains(paletteSuffix)) {
      paletteSubFolderName =
          'palette1_starfield'; // Fallback if suffix is unexpected
    }
    String paletteSpecificPath = 'assets/aether/$paletteSubFolderName/';

    // Helper for palette specific category icons - Check existence or use fallback
    // NOTE: Real check isn't feasible here, relying on convention.
    String pCatIcon(String catName, String fallback) {
      // Construct the expected path
      String specificPath =
          '${paletteSpecificPath}icon_${paletteSuffix}_${catName.toLowerCase()}.svg';
      // In a real app, you might have a predefined map of which icons actually exist per theme
      // For now, return the specific path assuming it exists. Fallback handled by getCategoryIcon caller.
      return specificPath;
    }

    // --- Define the commonIcons map using the AppModeTheme constants ---
    Map<String, String> commonIconsMap = {
      AppModeTheme.iconAdd: '${commonIconPath}ic_add.svg',
      AppModeTheme.iconSettings: '${commonIconPath}ic_settings.svg',
      AppModeTheme.iconCalendar: '${commonIconPath}ic_calendar.svg',
      AppModeTheme.iconCategory: '${commonIconPath}ic_category.svg',
      AppModeTheme.iconNotes: '${commonIconPath}ic_notes.svg',
      AppModeTheme.iconTheme: '${commonIconPath}ic_theme.svg',
      AppModeTheme.iconSync: '${commonIconPath}ic_sync.svg',
      AppModeTheme.iconPrivacy: '${commonIconPath}ic_privacy.svg',
      AppModeTheme.iconBooks: '${commonIconPath}ic_books.svg',
      AppModeTheme.iconRestaurant: '${commonIconPath}ic_restaurant.svg',
      // FIXED: Use the constant string key now
      AppModeTheme.iconSalary: '${commonIconPath}ic_salary.svg',
      // Add other AppModeTheme constants if they exist and have corresponding files
      // e.g., AppModeTheme.iconBack: 'path/to/back.svg',
    };
    // --- End commonIcons map definition ---

    // Helper lambda to determine the correct asset based on suffix
    String getNodeAsset(String type) {
      String assetName;
      switch (type) {
        case 'income':
          assetName = paletteSuffix == 'garden'
              ? 'butterfly_income_garden'
              : paletteSuffix == 'mystic'
                  ? 'mystic_eye_income'
                  : paletteSuffix == 'calm_sky'
                      ? 'cloud_income_calm'
                      : 'planet_income_starfield'; // Default starfield
          break;
        case 'expense':
          assetName = paletteSuffix == 'garden'
              ? 'tree_expense_garden'
              : paletteSuffix == 'mystic'
                  ? 'wand_expense_mystic'
                  : paletteSuffix == 'calm_sky'
                      ? 'rain_expense_calm'
                      : 'planet_expense_starfield'; // Default starfield
          break;
        case 'balance':
          assetName = paletteSuffix == 'garden'
              ? 'leaf_balance_garden'
              : paletteSuffix == 'mystic'
                  ? 'orb_balance_mystic'
                  : paletteSuffix == 'calm_sky'
                      ? 'moon_balance_calm'
                      : 'stars_overlay_starfield'; // Default starfield (was balance circle before?)
          break;
        default:
          assetName = 'planet_income_starfield'; // Fallback
      }
      return '$paletteSpecificPath$assetName.svg';
    }

    return ThemeAssetPaths(
        mainBackgroundDark:
            '${bgPath}bg_$paletteSuffix.svg', // Use suffix for background name convention
        mainBackgroundLight:
            '${bgPath}bg_$paletteSuffix.svg', // Same for light/dark in Aether
        fabGlow: '${paletteSpecificPath}button_glow_$paletteSuffix.svg',
        divider: null, // Aether themes might not use a standard divider asset
        focusRing:
            null, // Aether themes might not use a standard focus ring asset
        cardBackground: null, // Aether cards use surfaceVariant color, not SVG
        commonIcons: commonIconsMap, // Use the map defined above
        categoryIcons: {
          // Map known categories to specific Aether assets (use lowercase keys)
          'groceries':
              pCatIcon('groceries', '${commonIconPath}ic_groceries.svg'),
          'food': pCatIcon('food', '${commonIconPath}ic_restaurant.svg'),
          'transport':
              pCatIcon('transport', '${commonIconPath}ic_category.svg'),
          'entertainment':
              pCatIcon('entertainment', '${commonIconPath}ic_category.svg'),
          'medical': pCatIcon('medical', '${commonIconPath}ic_category.svg'),
          'subscription':
              pCatIcon('subscription', '${commonIconPath}ic_category.svg'),
          'utilities':
              pCatIcon('utilities', '${commonIconPath}ic_category.svg'),
          'housing': pCatIcon('housing', '${commonIconPath}ic_category.svg'),
          'salary': '${commonIconPath}ic_salary.svg', // Use common Aether icon
          'bonus': '${commonIconPath}ic_salary.svg',
          'freelance': '${commonIconPath}ic_salary.svg',
          'gift': '${commonIconPath}ic_salary.svg',
          'interest': '${commonIconPath}ic_salary.svg',
          'other': '${commonIconPath}ic_category.svg',
          // Account types
          'bank': pCatIcon('bank', '${commonIconPath}ic_category.svg'),
          'cash': pCatIcon('cash', '${commonIconPath}ic_category.svg'),
          'crypto': pCatIcon('crypto', '${commonIconPath}ic_category.svg'),
          'investment':
              pCatIcon('investment', '${commonIconPath}ic_category.svg'),
        },
        illustrations: {
          'empty_transactions': '${illustrationPath}empty_starscape.svg',
          'add_first': '${illustrationPath}add_first_transaction.svg',
          'planet_island': '${illustrationPath}planet_island.svg',
          'empty_filter': '${illustrationPath}empty_starscape.svg', // Example
        },
        charts: {
          // Common Aether Charts
          'balance_indicator': '${chartPath}balance_circle.svg',
          'weekly_sparkline': '${chartPath}weekly_sparkline.svg',
          'top_cat_income': '${chartPath}top_category_income.svg',
          'top_cat_food': '${chartPath}top_category_food.svg',
          'top_cat_bills': '${chartPath}top_category_bills.svg',
          'top_cat_entertainment': '${chartPath}top_category_entertainment.svg',
          // Palette specific elements for dashboard widgets
          'income_node': getNodeAsset('income'),
          'expense_node': getNodeAsset('expense'),
          'balance_node': getNodeAsset('balance'),
        });
  }
} // End of AppTheme class

// Helper Extension for String Capitalization
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
