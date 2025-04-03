import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // Import AppTheme for defaults
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode, CountryInfo
import 'package:expense_tracker/main.dart'; // Import logger

// Keys for SharedPreferences
const String _themeModeKey = 'app_theme_mode_v2';
const String _themeIdentifierKey = 'app_theme_identifier_v1';
const String _uiModeKey = 'app_ui_mode_v1'; // --- ADDED ---
const String _selectedCountryCodeKey = 'app_selected_country_code_v1';
const String _appLockEnabledKey = 'app_lock_enabled_v1';

abstract class SettingsLocalDataSource {
  // Theme Mode
  Future<void> saveThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();

  // Theme Identifier (Color Variant)
  Future<void> saveThemeIdentifier(String identifier);
  Future<String> getThemeIdentifier();

  // --- ADDED: UI Mode ---
  Future<void> saveUIMode(UIMode mode);
  Future<UIMode> getUIMode();
  // --- END ADDED ---

  // Country
  Future<void> saveSelectedCountryCode(String countryCode);
  Future<String?> getSelectedCountryCode(); // Can be null if never set

  // App Lock
  Future<void> saveAppLockEnabled(bool enabled);
  Future<bool> getAppLockEnabled();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences prefs;

  SettingsLocalDataSourceImpl({required this.prefs});

  @override
  Future<ThemeMode> getThemeMode() async {
    final String? themeString = prefs.getString(_themeModeKey);
    log.info("[SettingsDS] Getting Theme Mode: Stored value = '$themeString'");
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        // log.info("Defaulting to ThemeMode.system"); // Covered by SettingsState default
        return SettingsState.defaultThemeMode;
    }
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) async {
    String themeString;
    switch (mode) {
      case ThemeMode.light:
        themeString = 'light';
        break;
      case ThemeMode.dark:
        themeString = 'dark';
        break;
      case ThemeMode.system:
        themeString = 'system';
        break;
    }
    await prefs.setString(_themeModeKey, themeString);
    log.info("[SettingsDS] Saved Theme Mode: '$themeString'");
  }

  @override
  Future<String> getThemeIdentifier() async {
    final identifier = prefs.getString(_themeIdentifierKey) ??
        SettingsState.defaultThemeIdentifier;
    log.info(
        "[SettingsDS] Getting Theme Identifier: Stored value = '$identifier'");
    // Validate if the stored identifier is still valid
    if (AppTheme.availableThemeIdentifiers.contains(identifier)) {
      return identifier;
    } else {
      log.warning(
          "[SettingsDS] Stored theme identifier '$identifier' is invalid. Defaulting to ${SettingsState.defaultThemeIdentifier}.");
      return SettingsState.defaultThemeIdentifier; // Default if invalid
    }
  }

  @override
  Future<void> saveThemeIdentifier(String identifier) async {
    await prefs.setString(_themeIdentifierKey, identifier);
    log.info("[SettingsDS] Saved Theme Identifier: '$identifier'");
  }

  // --- ADDED: UI Mode Methods ---
  @override
  Future<UIMode> getUIMode() async {
    final String? modeString = prefs.getString(_uiModeKey);
    log.info("[SettingsDS] Getting UI Mode: Stored value = '$modeString'");
    switch (modeString) {
      case 'elemental':
        return UIMode.elemental;
      case 'quantum':
        return UIMode.quantum;
      case 'aether':
        return UIMode.aether;
      default:
        // log.info("Defaulting to UIMode.elemental"); // Covered by SettingsState default
        return SettingsState.defaultUIMode;
    }
  }

  @override
  Future<void> saveUIMode(UIMode mode) async {
    await prefs.setString(_uiModeKey, mode.name); // Store enum name
    log.info("[SettingsDS] Saved UI Mode: '${mode.name}'");
  }
  // --- END ADDED ---

  @override
  Future<String?> getSelectedCountryCode() async {
    final code = prefs.getString(_selectedCountryCodeKey);
    log.info(
        "[SettingsDS] Getting Selected Country Code: Stored value = '$code'");
    // No default here, BLoC handles defaulting if null
    return code;
  }

  @override
  Future<void> saveSelectedCountryCode(String countryCode) async {
    await prefs.setString(_selectedCountryCodeKey, countryCode);
    log.info("[SettingsDS] Saved Selected Country Code: '$countryCode'");
  }

  @override
  Future<bool> getAppLockEnabled() async {
    final enabled = prefs.getBool(_appLockEnabledKey) ??
        SettingsState.defaultAppLockEnabled;
    log.info("[SettingsDS] Getting App Lock Enabled: Stored value = $enabled");
    return enabled;
  }

  @override
  Future<void> saveAppLockEnabled(bool enabled) async {
    await prefs.setBool(_appLockEnabledKey, enabled);
    log.info("[SettingsDS] Saved App Lock Enabled: $enabled");
  }
}
