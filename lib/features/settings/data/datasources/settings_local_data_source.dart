import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // Import AppTheme for defaults
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode, CountryInfo
import 'package:expense_tracker/main.dart'; // Import logger

// Keys for SharedPreferences
const String _themeModeKey = 'app_theme_mode_v2';
const String _paletteIdentifierKey = 'app_palette_identifier_v1'; // RENAMED
const String _uiModeKey = 'app_ui_mode_v1';
const String _selectedCountryCodeKey = 'app_selected_country_code_v1';
const String _appLockEnabledKey = 'app_lock_enabled_v1';

abstract class SettingsLocalDataSource {
  // Theme Mode
  Future<void> saveThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();

  // Palette Identifier
  Future<void> savePaletteIdentifier(String identifier); // RENAMED
  Future<String> getPaletteIdentifier(); // RENAMED

  // UI Mode
  Future<void> saveUIMode(UIMode mode);
  Future<UIMode> getUIMode();

  // Country
  Future<void> saveSelectedCountryCode(String countryCode);
  Future<String?> getSelectedCountryCode();

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
    // log.info("[SettingsDS] Getting Theme Mode: Stored value = '$themeString'"); // Log less noise
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
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
  Future<String> getPaletteIdentifier() async {
    // RENAMED
    final identifier = prefs.getString(_paletteIdentifierKey) ??
        SettingsState.defaultPaletteIdentifier;
    // log.info("[SettingsDS] Getting Palette Identifier: Stored value = '$identifier'"); // Log less noise
    // Basic validation could happen here, but AppTheme handles fallbacks better
    return identifier;
  }

  @override
  Future<void> savePaletteIdentifier(String identifier) async {
    // RENAMED
    await prefs.setString(_paletteIdentifierKey, identifier);
    log.info("[SettingsDS] Saved Palette Identifier: '$identifier'");
  }

  @override
  Future<UIMode> getUIMode() async {
    final String? modeString = prefs.getString(_uiModeKey);
    // log.info("[SettingsDS] Getting UI Mode: Stored value = '$modeString'"); // Log less noise
    switch (modeString) {
      case 'elemental':
        return UIMode.elemental;
      case 'quantum':
        return UIMode.quantum;
      case 'aether':
        return UIMode.aether;
      default:
        return SettingsState.defaultUIMode;
    }
  }

  @override
  Future<void> saveUIMode(UIMode mode) async {
    await prefs.setString(_uiModeKey, mode.name);
    log.info("[SettingsDS] Saved UI Mode: '${mode.name}'");
  }

  @override
  Future<String?> getSelectedCountryCode() async {
    final code = prefs.getString(_selectedCountryCodeKey);
    // log.info("[SettingsDS] Getting Selected Country Code: Stored value = '$code'"); // Log less noise
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
    // log.info("[SettingsDS] Getting App Lock Enabled: Stored value = $enabled"); // Log less noise
    return enabled;
  }

  @override
  Future<void> saveAppLockEnabled(bool enabled) async {
    await prefs.setBool(_appLockEnabledKey, enabled);
    log.info("[SettingsDS] Saved App Lock Enabled: $enabled");
  }
}
