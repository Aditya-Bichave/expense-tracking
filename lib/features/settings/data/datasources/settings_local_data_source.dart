import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/core/theme/app_theme.dart'; // Import AppTheme for defaults
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import CountryInfo
import 'package:expense_tracker/main.dart'; // Import logger

// Keys for SharedPreferences
const String _themeModeKey =
    'app_theme_mode_v2'; // Use v2 to avoid conflicts if migrating
const String _themeIdentifierKey =
    'app_theme_identifier_v1'; // Key for selected theme ID
const String _selectedCountryCodeKey = 'app_selected_country_code_v1';
const String _appLockEnabledKey = 'app_lock_enabled_v1';
// Removed currency symbol key, derive from country

abstract class SettingsLocalDataSource {
  Future<void> saveThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();
  Future<void> saveThemeIdentifier(String identifier);
  Future<String> getThemeIdentifier();
  Future<void> saveSelectedCountryCode(String countryCode);
  Future<String?> getSelectedCountryCode(); // Can be null if never set
  Future<void> saveAppLockEnabled(bool enabled);
  Future<bool> getAppLockEnabled();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences prefs;

  SettingsLocalDataSourceImpl({required this.prefs});

  @override
  Future<ThemeMode> getThemeMode() async {
    final String? themeString = prefs.getString(_themeModeKey);
    log.info("Getting Theme Mode: Stored value = '$themeString'");
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        log.info("Defaulting to ThemeMode.system");
        return ThemeMode.system; // Default to system
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
    log.info("Saved Theme Mode: '$themeString'");
  }

  @override
  Future<String> getThemeIdentifier() async {
    final identifier =
        prefs.getString(_themeIdentifierKey) ?? AppTheme.defaultThemeId;
    log.info("Getting Theme Identifier: Stored value = '$identifier'");
    // Validate if the stored identifier is still valid
    if (AppTheme.availableThemeIdentifiers.contains(identifier)) {
      return identifier;
    } else {
      log.warning(
          "Stored theme identifier '$identifier' is invalid. Defaulting to ${AppTheme.defaultThemeId}.");
      return AppTheme.defaultThemeId; // Default if invalid
    }
  }

  @override
  Future<void> saveThemeIdentifier(String identifier) async {
    await prefs.setString(_themeIdentifierKey, identifier);
    log.info("Saved Theme Identifier: '$identifier'");
  }

  @override
  Future<String?> getSelectedCountryCode() async {
    final code = prefs.getString(_selectedCountryCodeKey);
    log.info("Getting Selected Country Code: Stored value = '$code'");
    // No default here, BLoC handles defaulting if null
    return code;
  }

  @override
  Future<void> saveSelectedCountryCode(String countryCode) async {
    await prefs.setString(_selectedCountryCodeKey, countryCode);
    log.info("Saved Selected Country Code: '$countryCode'");
  }

  @override
  Future<bool> getAppLockEnabled() async {
    final enabled =
        prefs.getBool(_appLockEnabledKey) ?? false; // Default to false
    log.info("Getting App Lock Enabled: Stored value = $enabled");
    return enabled;
  }

  @override
  Future<void> saveAppLockEnabled(bool enabled) async {
    await prefs.setBool(_appLockEnabledKey, enabled);
    log.info("Saved App Lock Enabled: $enabled");
  }
}
