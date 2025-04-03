// lib/features/settings/presentation/bloc/settings_state.dart
part of 'settings_bloc.dart';

// --- Status Enums ---
enum SettingsStatus { initial, loading, loaded, error }

enum PackageInfoStatus { initial, loading, loaded, error }

enum DataManagementStatus { initial, loading, success, error }

// --- UI Mode Enum ---
enum UIMode { elemental, quantum, aether }

// --- Country Info Helper ---
// REMOVED CountryInfo definition (moved to core/data/countries.dart)
// Use AppCountry from core/data/countries.dart instead

class SettingsState extends Equatable {
  // --- Main settings ---
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String paletteIdentifier; // Name remains the same
  final UIMode uiMode;
  final String selectedCountryCode; // Keep the code
  final bool isAppLockEnabled;
  final String? errorMessage;

  // --- Package info ---
  final PackageInfoStatus packageInfoStatus;
  final String? appVersion;
  final String? packageInfoError;

  // --- Data Management ---
  final DataManagementStatus dataManagementStatus;
  final String? dataManagementMessage;

  // --- Static Defaults & Data ---
  static const defaultThemeMode = ThemeMode.system;
  // Use a default palette identifier from AppTheme
  static const defaultPaletteIdentifier = AppTheme.elementalPalette1;
  static const defaultUIMode = UIMode.elemental;
  // Use default country code from AppCountries
  static const String defaultCountryCode = AppCountries.defaultCountryCode;
  // Use default from AppConstants
  static const bool defaultAppLockEnabled = AppConstants.defaultAppLockEnabled;

  // REMOVED availableCountries (moved to core/data/countries.dart)
  // REMOVED getCurrencyForCountry (moved to core/data/countries.dart)

  // --- Computed Property ---
  // Use the helper from AppCountries
  String get currencySymbol =>
      AppCountries.getCurrencyForCountry(selectedCountryCode);

  // --- Constructor ---
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode,
    this.paletteIdentifier = defaultPaletteIdentifier,
    this.uiMode = defaultUIMode,
    this.selectedCountryCode =
        defaultCountryCode, // Use default from AppCountries
    this.isAppLockEnabled =
        defaultAppLockEnabled, // Use default from AppConstants
    this.errorMessage,
    this.packageInfoStatus = PackageInfoStatus.initial,
    this.appVersion,
    this.packageInfoError,
    this.dataManagementStatus = DataManagementStatus.initial,
    this.dataManagementMessage,
  });

  // --- copyWith (no changes needed here for extraction) ---
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
    DataManagementStatus? dataManagementStatus,
    String? dataManagementMessage,
    bool clearMainError = false,
    bool clearPackageInfoError = false,
    bool clearDataManagementMessage = false,
    bool clearAllMessages = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      paletteIdentifier: paletteIdentifier ?? this.paletteIdentifier,
      uiMode: uiMode ?? this.uiMode,
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      errorMessage: clearAllMessages || clearMainError
          ? null
          : errorMessage ?? this.errorMessage,
      packageInfoStatus: packageInfoStatus ?? this.packageInfoStatus,
      appVersion: appVersion ?? this.appVersion,
      packageInfoError: clearAllMessages || clearPackageInfoError
          ? null
          : packageInfoError ?? this.packageInfoError,
      dataManagementStatus: dataManagementStatus ?? this.dataManagementStatus,
      dataManagementMessage: clearAllMessages || clearDataManagementMessage
          ? null
          : dataManagementMessage ?? this.dataManagementMessage,
    );
  }

  // --- props (ensure currencySymbol is included) ---
  @override
  List<Object?> get props => [
        status,
        themeMode,
        paletteIdentifier,
        uiMode,
        selectedCountryCode,
        currencySymbol, // Make sure this computed property is in props
        isAppLockEnabled,
        errorMessage,
        packageInfoStatus,
        appVersion,
        packageInfoError,
        dataManagementStatus,
        dataManagementMessage,
      ];
}
