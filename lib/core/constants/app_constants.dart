// lib/core/constants/app_constants.dart

abstract class AppConstants {
  static const Duration networkTimeout = Duration(seconds: 15);
  static const String appName = "Financial OS"; // Centralized app name

  // Default values moved from SettingsState (can be used across app)
  // Note: ThemeMode itself doesn't fit well here, keep default in SettingsState
  // static const defaultPaletteIdentifier = AppTheme.elementalPalette1; // Managed by theme config/AppTheme
  // static const defaultUIMode = UIMode.elemental; // Managed by theme config/AppTheme
  // static const defaultCountryCode = 'US'; // Managed by AppCountries
  static const bool defaultAppLockEnabled = false;

  // Backup/Restore related keys
  static const String backupMetaKey = 'metadata';
  static const String backupDataKey = 'data';
  static const String backupVersionKey = 'appVersion';
  static const String backupTimestampKey = 'backupTimestamp';
  static const String backupFormatVersionKey = 'formatVersion';
  static const String backupFormatVersion = '1.0';
  static const String backupAccountsKey = 'accounts';
  static const String backupExpensesKey = 'expenses';
  static const String backupIncomesKey = 'incomes';
}

/// External destinations opened from the settings screen.
///
/// Kept in one place so the page, the legal section and their tests all agree
/// on the exact URL rather than repeating string literals.
abstract class ExternalUrls {
  static const String help = 'https://example.com/help';
  static const String privacy = 'https://example.com/privacy';
  static const String terms = 'https://example.com/terms';
}
