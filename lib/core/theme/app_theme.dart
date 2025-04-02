import 'package:flutter/material.dart';

// Structure to hold both light and dark theme data
class AppThemeData {
  final ThemeData light;
  final ThemeData dark;

  const AppThemeData({required this.light, required this.dark});
}

class AppTheme {
  static const String appName = "Spend Savvy"; // Updated App Name

  // Theme Identifiers (Keys for storage and lookup)
  static const String defaultThemeId = 'default';
  static const String pastelPeachId = 'pastelPeach';
  static const String mintyFreshId = 'mintyFresh';
  static const String lavenderDreamId = 'lavenderDream';
  static const String sunnyYellowId = 'sunnyYellow';
  static const String oceanBlueId = 'oceanBlue';
  static const String cherryBlossomId = 'cherryBlossom';

  // Map of theme identifiers to their names for UI
  static final Map<String, String> themeNames = {
    defaultThemeId: 'Default Purple',
    pastelPeachId: 'Pastel Peach',
    mintyFreshId: 'Minty Fresh',
    lavenderDreamId: 'Lavender Dream',
    sunnyYellowId: 'Sunny Yellow',
    oceanBlueId: 'Ocean Blue',
    cherryBlossomId: 'Cherry Blossom',
  };

  // Map storing all theme data
  static final Map<String, AppThemeData> _themes = {
    defaultThemeId: _buildThemeData(
        seedColor: Colors.deepPurple, brightness: Brightness.light),
    pastelPeachId: _buildThemeData(
        seedColor: const Color(0xFFFFE5B4),
        brightness: Brightness.light), // Peach
    mintyFreshId: _buildThemeData(
        seedColor: const Color(0xFFADEBAD),
        brightness: Brightness.light), // Mint
    lavenderDreamId: _buildThemeData(
        seedColor: const Color(0xFFE6E6FA),
        brightness: Brightness.light), // Lavender
    sunnyYellowId: _buildThemeData(
        seedColor: const Color(0xFFFFFACD),
        brightness: Brightness.light), // Lemon Chiffon
    oceanBlueId: _buildThemeData(
        seedColor: const Color(0xFFADD8E6),
        brightness: Brightness.light), // Light Blue
    cherryBlossomId: _buildThemeData(
        seedColor: const Color(0xFFFFB7C5),
        brightness: Brightness.light), // Light Pink
  };

  // Helper to build both light and dark variants from a seed color
  static AppThemeData _buildThemeData(
      {required Color seedColor, required Brightness brightness}) {
    final lightTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        elevation: 1,
        centerTitle: true,
      ),
      // Add other shared theme properties if needed
    );

    final darkTheme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: seedColor,
        brightness: Brightness.dark,
        // Optionally adjust dark theme contrast or surface colors
        // primary: seedColor, // Ensure primary stays consistent if needed
        // surface: Colors.grey[850], // Example: slightly different surface
      ),
      appBarTheme: const AppBarTheme(
        elevation: 1,
        centerTitle: true,
      ),
      // Add other shared theme properties if needed
    );

    return AppThemeData(light: lightTheme, dark: darkTheme);
  }

  // Get theme data by identifier, defaulting to 'default' if not found
  static AppThemeData getThemeDataByIdentifier(String identifier) {
    return _themes[identifier] ?? _themes[defaultThemeId]!;
  }

  // Get the list of available theme identifiers
  static List<String> get availableThemeIdentifiers => _themes.keys.toList();

  // Get the display name for a theme identifier
  static String getThemeName(String identifier) {
    return themeNames[identifier] ?? 'Unknown Theme';
  }

  // --- Kept Original Themes (can be removed if only using _buildThemeData) ---
  // static ThemeData get lightTheme => _themes[defaultThemeId]!.light;
  // static ThemeData get darkTheme => _themes[defaultThemeId]!.dark;
}
