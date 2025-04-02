import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Keys for SharedPreferences
const String _themeModeKey = 'app_theme_mode';
const String _currencySymbolKey = 'app_currency_symbol';
const String _appLockEnabledKey = 'app_lock_enabled';

abstract class SettingsLocalDataSource {
  Future<void> saveThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();
  Future<void> saveCurrencySymbol(String symbol);
  Future<String?> getCurrencySymbol();
  Future<void> saveAppLockEnabled(bool enabled);
  Future<bool> getAppLockEnabled();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences prefs;

  SettingsLocalDataSourceImpl({required this.prefs});

  @override
  Future<ThemeMode> getThemeMode() async {
    final String? themeString = prefs.getString(_themeModeKey);
    switch (themeString) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        // Default to system if not set or invalid
        return ThemeMode.system;
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
  }

  @override
  Future<String?> getCurrencySymbol() async {
    // Default to 'USD' if not set, adjust as needed for your app's default
    // Returning null allows the BLoC to handle the default.
    return prefs.getString(_currencySymbolKey);
  }

  @override
  Future<void> saveCurrencySymbol(String symbol) async {
    await prefs.setString(_currencySymbolKey, symbol);
  }

  @override
  Future<bool> getAppLockEnabled() async {
    // Default to false if not set
    return prefs.getBool(_appLockEnabledKey) ?? false;
  }

  @override
  Future<void> saveAppLockEnabled(bool enabled) async {
    await prefs.setBool(_appLockEnabledKey, enabled);
  }
}
