// lib/features/settings/data/datasources/settings_local_data_source.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Removed: import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/main.dart';

// Import constants
import 'package:expense_tracker/core/constants/pref_keys.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/data/countries.dart';

// REMOVED Keys (moved to core/constants/pref_keys.dart)

abstract class SettingsLocalDataSource {
  Future<void> saveThemeMode(ThemeMode mode);
  Future<ThemeMode> getThemeMode();
  Future<void> savePaletteIdentifier(String identifier);
  Future<String> getPaletteIdentifier();
  Future<void> saveUIMode(UIMode mode);
  Future<UIMode> getUIMode();
  Future<void> saveSelectedCountryCode(String countryCode);
  Future<String?> getSelectedCountryCode();
  Future<void> saveAppLockEnabled(bool enabled);
  Future<bool> getAppLockEnabled();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final SharedPreferences prefs;

  SettingsLocalDataSourceImpl({required this.prefs});

  @override
  Future<ThemeMode> getThemeMode() async {
    // Use constant key
    final String? themeString = prefs.getString(PrefKeys.themeMode);
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
    // Use constant key
    await prefs.setString(PrefKeys.themeMode, themeString);
    log.info("[SettingsDS] Saved Theme Mode: '$themeString'");
  }

  @override
  Future<String> getPaletteIdentifier() async {
    // Use constant key and default from SettingsState
    final identifier = prefs.getString(PrefKeys.paletteIdentifier) ??
        SettingsState.defaultPaletteIdentifier;
    return identifier;
  }

  @override
  Future<void> savePaletteIdentifier(String identifier) async {
    // Use constant key
    await prefs.setString(PrefKeys.paletteIdentifier, identifier);
    log.info("[SettingsDS] Saved Palette Identifier: '$identifier'");
  }

  @override
  Future<UIMode> getUIMode() async {
    // Use constant key
    final String? modeString = prefs.getString(PrefKeys.uiMode);
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
    // Use constant key
    await prefs.setString(PrefKeys.uiMode, mode.name);
    log.info("[SettingsDS] Saved UI Mode: '${mode.name}'");
  }

  @override
  Future<String?> getSelectedCountryCode() async {
    // Use constant key
    final code = prefs.getString(PrefKeys.selectedCountryCode);
    return code;
  }

  @override
  Future<void> saveSelectedCountryCode(String countryCode) async {
    // Use constant key
    await prefs.setString(PrefKeys.selectedCountryCode, countryCode);
    log.info("[SettingsDS] Saved Selected Country Code: '$countryCode'");
  }

  @override
  Future<bool> getAppLockEnabled() async {
    // Use constant key and default from AppConstants
    final enabled = prefs.getBool(PrefKeys.appLockEnabled) ??
        AppConstants.defaultAppLockEnabled;
    return enabled;
  }

  @override
  Future<void> saveAppLockEnabled(bool enabled) async {
    // Use constant key
    await prefs.setBool(PrefKeys.appLockEnabled, enabled);
    log.info("[SettingsDS] Saved App Lock Enabled: $enabled");
  }
}
