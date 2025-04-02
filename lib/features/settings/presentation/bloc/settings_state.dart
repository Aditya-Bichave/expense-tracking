part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, loaded, error }

// Add status specifically for package info loading
enum PackageInfoStatus { initial, loading, loaded, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String? currencySymbol;
  final bool isAppLockEnabled;
  final String? errorMessage;

  // New fields for App Version
  final PackageInfoStatus packageInfoStatus;
  final String? appVersion;
  final String? packageInfoError;

  // --- Static Defaults ---
  static const defaultThemeMode = ThemeMode.system;
  static const defaultCurrencySymbol = 'USD'; // Default currency
  static const defaultAppLockEnabled = false;
  // --- End Static Defaults ---

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode,
    this.currencySymbol = defaultCurrencySymbol,
    this.isAppLockEnabled = defaultAppLockEnabled,
    this.errorMessage,
    // Initialize new fields
    this.packageInfoStatus = PackageInfoStatus.initial,
    this.appVersion,
    this.packageInfoError,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? isAppLockEnabled,
    String? errorMessage,
    // Copy method for new fields
    PackageInfoStatus? packageInfoStatus,
    String? appVersion,
    String? packageInfoError,
    bool clearMainError = false, // Helper flags
    bool clearPackageInfoError = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      errorMessage: clearMainError ? null : errorMessage ?? this.errorMessage,
      // Handle new fields in copyWith
      packageInfoStatus: packageInfoStatus ?? this.packageInfoStatus,
      appVersion: appVersion ?? this.appVersion,
      packageInfoError: clearPackageInfoError
          ? null
          : packageInfoError ?? this.packageInfoError,
    );
  }

  @override
  List<Object?> get props => [
        status,
        themeMode,
        currencySymbol,
        isAppLockEnabled,
        errorMessage,
        // Add new fields to props
        packageInfoStatus,
        appVersion,
        packageInfoError,
      ];
}
