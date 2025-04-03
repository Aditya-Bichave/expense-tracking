import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Structure to hold both light and dark theme data
class AppThemeData {
  final ThemeData light;
  final ThemeData dark;

  const AppThemeData({required this.light, required this.dark});
}

class AppTheme {
  static const String appName = "Spend Savvy";

  // --- UI Mode Identifiers ---
  static const String elementalModeId = 'elemental';
  static const String quantumModeId = 'quantum';
  static const String aetherModeId = 'aether';

  // --- Theme (Color Variant / Sub-Theme) Identifiers ---
  // Elemental
  static const String elementalThemeId = 'elemental_default';
  // Basic Color Variants (Can be applied to Elemental or maybe Quantum/Aether if designed)
  static const String pastelPeachId = 'pastelPeach';
  static const String mintyFreshId = 'mintyFresh';
  static const String lavenderDreamId = 'lavenderDream';
  static const String sunnyYellowId = 'sunnyYellow';
  static const String oceanBlueId = 'oceanBlue';
  static const String cherryBlossomId = 'cherryBlossom';
  // Quantum
  static const String quantumMonoThemeId = 'quantum_mono'; // Example
  static const String quantumTerminalThemeId = 'quantum_terminal'; // Example
  // Aether
  static const String aetherGardenThemeId = 'aether_garden';
  static const String aetherConstellationThemeId = 'aether_constellation';

  // Map of UI mode enum to display names
  static final Map<UIMode, String> uiModeNames = {
    UIMode.elemental: 'Elemental (Default)',
    UIMode.quantum: 'Quantum (Data-Dense)',
    UIMode.aether: 'Aether (Visual)',
  };

  // Map of theme (color variant / Aether sub-theme) identifiers to display names
  static final Map<String, String> themeNames = {
    // Elemental Themes
    elementalThemeId: 'Default Purple',
    // Color Variants (Can apply to Elemental)
    pastelPeachId: 'Pastel Peach',
    mintyFreshId: 'Minty Fresh',
    lavenderDreamId: 'Lavender Dream',
    sunnyYellowId: 'Sunny Yellow',
    oceanBlueId: 'Ocean Blue',
    cherryBlossomId: 'Cherry Blossom',
    // Quantum Themes
    quantumMonoThemeId: 'Quantum Mono',
    quantumTerminalThemeId: 'Quantum Terminal',
    // Aether Themes
    aetherGardenThemeId: 'Aether Garden',
    aetherConstellationThemeId: 'Aether Constellation',
  };

  // Map storing ALL theme data definitions
  static final Map<String, AppThemeData> _themes = {
    // Elemental
    elementalThemeId: _buildElementalTheme(),
    // Color Variants
    pastelPeachId: _buildThemeData(seedColor: const Color(0xFFFFE5B4)),
    mintyFreshId: _buildThemeData(seedColor: const Color(0xFFADEBAD)),
    lavenderDreamId: _buildThemeData(seedColor: const Color(0xFFE6E6FA)),
    sunnyYellowId: _buildThemeData(seedColor: const Color(0xFFFFFACD)),
    oceanBlueId: _buildThemeData(seedColor: const Color(0xFFADD8E6)),
    cherryBlossomId: _buildThemeData(seedColor: const Color(0xFFFFB7C5)),
    // Quantum
    quantumMonoThemeId: _buildQuantumMonoTheme(),
    quantumTerminalThemeId: _buildQuantumTerminalTheme(),
    // Aether
    aetherGardenThemeId: _buildAetherGardenTheme(),
    aetherConstellationThemeId: _buildAetherConstellationTheme(),
  };

  // --- Elemental Theme Builder ---
  static AppThemeData _buildElementalTheme() {
    return _buildThemeData(seedColor: Colors.deepPurple);
  }

  // --- Quantum Theme Builders (Phase 3) ---
  static AppThemeData _buildQuantumMonoTheme() {
    const primaryColor = Color(0xFFE0E0E0); // Light Gray
    const accentColor = Color(0xFF64FFDA); // Teal accent
    final lightColors = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: accentColor,
      // High contrast background/surface
      background: Colors.white,
      surface: Colors.white,
      onBackground: Colors.black,
      onSurface: Colors.black,
      error: Colors.redAccent.shade700,
      onError: Colors.white,
    );
    final darkColors = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: accentColor,
      // High contrast background/surface
      background: const Color(0xFF121212),
      surface: const Color(0xFF1E1E1E),
      onBackground: Colors.white,
      onSurface: Colors.white,
      error: Colors.redAccent.shade400,
      onError: Colors.black,
    );

    return _buildBaseTheme(
      lightColorScheme: lightColors,
      darkColorScheme: darkColors,
      useQuantumDensity: true, // Apply density settings
    );
  }

  static AppThemeData _buildQuantumTerminalTheme() {
    const primaryColor = Color(0xFF4CAF50); // Green text
    const accentColor = Color(0xFF8BC34A); // Lighter green
    final lightColors = ColorScheme.fromSeed(
      // Less relevant for terminal, but provide
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: accentColor,
      background: const Color(0xFFFAFAFA),
      surface: const Color(0xFFFFFFFF),
      onBackground: const Color(0xFF333333),
      onSurface: const Color(0xFF333333),
      error: Colors.red.shade700,
      onError: Colors.white,
    );
    final darkColors = ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: primaryColor,
      secondary: accentColor,
      background: const Color(0xFF0A0F0A), // Very dark green/black
      surface: const Color(0xFF111811), // Slightly lighter dark green/black
      onBackground: const Color(0xFF66BB6A), // Primary green for text
      onSurface: const Color(0xFF81C784), // Lighter green for text
      error: Colors.redAccent.shade200,
      onError: Colors.black,
    );

    return _buildBaseTheme(
      lightColorScheme: lightColors,
      darkColorScheme: darkColors,
      useQuantumDensity: true,
      // Optionally use a monospace font for terminal theme
      // fontFamily: 'RobotoMono', // Ensure font is added to pubspec.yaml
    );
  }

  // --- Aether Theme Builders (Phase 4 & 5) ---
  static AppThemeData _buildAetherGardenTheme() {
    const seedColor = Color(0xFF4CAF50); // Green
    const secondaryColor = Color(0xFFC8E6C9); // Light Green
    const accentColor = Color(0xFFFFC107); // Amber/Gold (Flower accent)

    final lightColors = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
        primary: seedColor,
        secondary: secondaryColor,
        // Tertiary can be used for accents
        tertiary: accentColor,
        background: const Color(0xFFF0FFF0), // Honeydew
        surface: Colors.white);

    final darkColors = ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        primary: seedColor, // Keep primary green
        secondary: Colors.green.shade800, // Darker secondary
        tertiary: accentColor,
        background: const Color(0xFF1B2E1B), // Dark forest green
        surface: const Color(0xFF2E4D2E) // Slightly lighter dark green
        );

    return _buildBaseTheme(
      lightColorScheme: lightColors,
      darkColorScheme: darkColors,
      // Potentially different font or slightly less density than elemental
      // fontFamily: 'YourGardenFont',
    );
  }

  static AppThemeData _buildAetherConstellationTheme() {
    const seedColor = Color(0xFF3F51B5); // Indigo
    const secondaryColor = Color(0xFFC5CAE9); // Light Indigo
    const accentColor = Color(0xFFFFEB3B); // Yellow (Stars)

    final lightColors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
      primary: seedColor,
      secondary: secondaryColor,
      tertiary: accentColor,
      background: const Color(0xFFF0F4FF), // Very light blue/indigo
      surface: Colors.white,
    );

    final darkColors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
      primary: const Color(0xFF9FA8DA), // Lighter Indigo for primary in dark
      secondary: const Color(0xFF303F9F), // Darker secondary
      tertiary: accentColor,
      background: const Color(0xFF0F132A), // Very dark blue
      surface: const Color(0xFF1A234A), // Slightly lighter dark blue
    );

    return _buildBaseTheme(
      lightColorScheme: lightColors,
      darkColorScheme: darkColors,
      // Potentially different font
      // fontFamily: 'YourConstellationFont',
    );
  }

  // Base theme builder - used by all modes
  static AppThemeData _buildBaseTheme({
    required ColorScheme lightColorScheme,
    required ColorScheme darkColorScheme,
    bool useQuantumDensity = false, // Flag for Quantum specific tweaks
    String? fontFamily, // Optional custom font
  }) {
    final textTheme = fontFamily != null
        ? TextTheme(
            // Define text styles using the custom font
            // displayLarge: TextStyle(fontFamily: fontFamily, ...),
            // titleMedium: TextStyle(fontFamily: fontFamily, ...),
            // bodyMedium: TextStyle(fontFamily: fontFamily, ...),
            )
        : null; // Use default text theme if no font specified

    // Common theme properties
    final commonAppBarTheme = AppBarTheme(
      elevation: useQuantumDensity ? 0 : 1, // No elevation in Quantum
      centerTitle: true,
      shape: useQuantumDensity
          ? Border(
              bottom:
                  BorderSide(color: lightColorScheme.outlineVariant, width: 1))
          : null, // Border for Quantum
    );

    final commonCardTheme = CardTheme(
      elevation: useQuantumDensity ? 0.5 : 1, // Reduced elevation for Quantum
      margin: useQuantumDensity
          ? const EdgeInsets.symmetric(
              horizontal: 4.0, vertical: 2.0) // Tighter margins
          : const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      shape: useQuantumDensity
          ? RoundedRectangleBorder(
              // Use borders for Quantum
              side:
                  BorderSide(color: lightColorScheme.outlineVariant, width: 1),
              borderRadius: BorderRadius.circular(4),
            )
          : null, // Default shape otherwise
      clipBehavior: Clip.antiAlias,
    );

    final commonInputDecorationTheme = InputDecorationTheme(
      border: const OutlineInputBorder(),
      isDense: useQuantumDensity, // Dense inputs for Quantum
      contentPadding: useQuantumDensity // Reduced padding for Quantum
          ? const EdgeInsets.symmetric(horizontal: 10, vertical: 12)
          : null, // Default padding otherwise
    );

    final commonListTileTheme = ListTileThemeData(
      dense: useQuantumDensity, // Dense ListTiles for Quantum
      contentPadding: useQuantumDensity
          ? const EdgeInsets.symmetric(horizontal: 12.0) // Reduced padding
          : null,
    );

    // Light Theme Definition
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      appBarTheme: commonAppBarTheme.copyWith(
        backgroundColor:
            lightColorScheme.surface, // Use surface for light AppBar
        foregroundColor: lightColorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.dark, // For status bar icons
        shape: useQuantumDensity
            ? Border(
                bottom: BorderSide(
                    color: lightColorScheme.outlineVariant, width: 1))
            : null,
      ),
      cardTheme: commonCardTheme.copyWith(
        shape: useQuantumDensity
            ? RoundedRectangleBorder(
                side: BorderSide(
                    color: lightColorScheme.outlineVariant, width: 1),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
      ),
      inputDecorationTheme: commonInputDecorationTheme,
      listTileTheme: commonListTileTheme,
      visualDensity:
          useQuantumDensity ? VisualDensity.compact : VisualDensity.standard,
      textTheme: textTheme,
      pageTransitionsTheme: useQuantumDensity // Minimal animations for Quantum
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : null, // Default transitions otherwise
      // Add other common overrides based on density etc.
      splashFactory: useQuantumDensity
          ? NoSplash.splashFactory
          : InkSparkle.splashFactory, // No splash for Quantum
      highlightColor: useQuantumDensity ? Colors.transparent : null,
    );

    // Dark Theme Definition
    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      appBarTheme: commonAppBarTheme.copyWith(
        backgroundColor:
            darkColorScheme.surface, // Use surface for dark AppBar too
        foregroundColor: darkColorScheme.onSurface,
        systemOverlayStyle: SystemUiOverlayStyle.light, // For status bar icons
        shape: useQuantumDensity
            ? Border(
                bottom:
                    BorderSide(color: darkColorScheme.outlineVariant, width: 1))
            : null,
      ),
      cardTheme: commonCardTheme.copyWith(
        shape: useQuantumDensity
            ? RoundedRectangleBorder(
                side:
                    BorderSide(color: darkColorScheme.outlineVariant, width: 1),
                borderRadius: BorderRadius.circular(4),
              )
            : null,
        surfaceTintColor: useQuantumDensity
            ? Colors.transparent
            : null, // Fix Quantum dark card tint
      ),
      inputDecorationTheme: commonInputDecorationTheme,
      listTileTheme: commonListTileTheme,
      visualDensity:
          useQuantumDensity ? VisualDensity.compact : VisualDensity.standard,
      textTheme: textTheme,
      pageTransitionsTheme: useQuantumDensity // Minimal animations for Quantum
          ? const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.linux: FadeUpwardsPageTransitionsBuilder(),
                TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
                TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
              },
            )
          : null, // Default transitions otherwise
      splashFactory: useQuantumDensity
          ? NoSplash.splashFactory
          : InkSparkle.splashFactory, // No splash for Quantum
      highlightColor: useQuantumDensity ? Colors.transparent : null,
    );

    return AppThemeData(light: lightTheme, dark: darkTheme);
  }

  // Helper for existing color variants (uses default density)
  static AppThemeData _buildThemeData({required Color seedColor}) {
    final lightColors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final darkColors = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return _buildBaseTheme(
        lightColorScheme: lightColors, darkColorScheme: darkColors);
  }

  // Get theme data by a specific *theme identifier*
  static AppThemeData getThemeDataByIdentifier(String identifier) {
    return _themes[identifier] ??
        _themes[elementalThemeId]!; // Fallback to elemental default
  }

  // Get the list of available theme *identifiers* (all themes defined)
  static List<String> get availableThemeIdentifiers => _themes.keys.toList();

  // Get the display name for a theme *identifier*
  static String getThemeName(String identifier) {
    return themeNames[identifier] ?? identifier.capitalize(); // Fallback name
  }
}

// Helper extension
extension StringHelperExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
