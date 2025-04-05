// lib/features/settings/presentation/bloc/settings_state.dart
part of 'settings_bloc.dart';

// --- Status Enums ---
enum SettingsStatus { initial, loading, loaded, error }

enum PackageInfoStatus { initial, loading, loaded, error }
// REMOVED DataManagementStatus enum

// --- UI Mode Enum ---
enum UIMode { elemental, quantum, aether }

class SettingsState extends Equatable {
  // --- Main settings ---
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String paletteIdentifier;
  final UIMode uiMode;
  final String selectedCountryCode;
  final bool isAppLockEnabled;
  final String? errorMessage; // Error for main settings loading/saving

  // --- Package info ---
  final PackageInfoStatus packageInfoStatus;
  final String? appVersion;
  final String? packageInfoError;

  // REMOVED Data Management properties
  // final DataManagementStatus dataManagementStatus;
  // final String? dataManagementMessage;

  // --- Static Defaults & Data ---
  static const defaultThemeMode = ThemeMode.system;
  static const defaultPaletteIdentifier = AppTheme.elementalPalette1;
  static const defaultUIMode = UIMode.elemental;
  static const String defaultCountryCode = AppCountries.defaultCountryCode;
  static const bool defaultAppLockEnabled = AppConstants.defaultAppLockEnabled;

  // --- Computed Property ---
  String get currencySymbol =>
      AppCountries.getCurrencyForCountry(selectedCountryCode);

  // --- Constructor ---
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode,
    this.paletteIdentifier = defaultPaletteIdentifier,
    this.uiMode = defaultUIMode,
    this.selectedCountryCode = defaultCountryCode,
    this.isAppLockEnabled = defaultAppLockEnabled,
    this.errorMessage,
    this.packageInfoStatus = PackageInfoStatus.initial,
    this.appVersion,
    this.packageInfoError,
    // REMOVED dataManagementStatus and dataManagementMessage from constructor
  });

  // --- copyWith (Removed Data Management properties) ---
  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    String? paletteIdentifier,
    UIMode? uiMode,
    String? selectedCountryCode,
    bool? isAppLockEnabled,
    String? errorMessage,
    PackageInfoStatus? packageInfoStatus,
    String? appVersion,
    String? packageInfoError,
    // REMOVED dataManagementStatus and dataManagementMessage params
    bool clearErrorMessage = false, // Renamed from clearMainError
    bool clearPackageInfoError = false,
    // REMOVED clearDataManagementMessage
    bool clearAllMessages =
        false, // Clears both settings and package info errors
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      paletteIdentifier: paletteIdentifier ?? this.paletteIdentifier,
      uiMode: uiMode ?? this.uiMode,
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      errorMessage: clearAllMessages || clearErrorMessage
          ? null
          : errorMessage ?? this.errorMessage,
      packageInfoStatus: packageInfoStatus ?? this.packageInfoStatus,
      appVersion: appVersion ?? this.appVersion,
      packageInfoError: clearAllMessages || clearPackageInfoError
          ? null
          : packageInfoError ?? this.packageInfoError,
      // REMOVED dataManagementStatus and dataManagementMessage assignments
    );
  }

  // --- props (Removed Data Management properties) ---
  @override
  List<Object?> get props => [
        status,
        themeMode,
        paletteIdentifier,
        uiMode,
        selectedCountryCode,
        currencySymbol,
        isAppLockEnabled,
        errorMessage,
        packageInfoStatus,
        appVersion,
        packageInfoError,
        // REMOVED dataManagementStatus and dataManagementMessage
      ];
}
