part of 'settings_bloc.dart';

// --- Status Enums ---
enum SettingsStatus { initial, loading, loaded, error }

enum PackageInfoStatus { initial, loading, loaded, error }

enum DataManagementStatus { initial, loading, success, error }

// --- UI Mode Enum ---
enum UIMode { elemental, quantum, aether }

// --- Country Info Helper ---
class CountryInfo {
  final String code; // e.g., 'US', 'GB', 'IN'
  final String name; // e.g., 'United States', 'United Kingdom', 'India'
  final String currencySymbol; // e.g., '$', '£', '₹'

  const CountryInfo(
      {required this.code, required this.name, required this.currencySymbol});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryInfo &&
          runtimeType == other.runtimeType &&
          code == other.code;

  @override
  int get hashCode => code.hashCode;
}

class SettingsState extends Equatable {
  // --- Main settings ---
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String paletteIdentifier; // RENAMED from selectedThemeIdentifier
  final UIMode uiMode;
  final String selectedCountryCode;
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
  static const defaultPaletteIdentifier =
      AppTheme.elementalPalette1; // Use specific palette ID
  static const defaultUIMode = UIMode.elemental;
  static const defaultCountryCode = 'US';
  static const defaultAppLockEnabled = false;

  static const List<CountryInfo> availableCountries = [
    CountryInfo(code: 'US', name: 'United States', currencySymbol: '\$'),
    CountryInfo(code: 'GB', name: 'United Kingdom', currencySymbol: '£'),
    CountryInfo(code: 'EU', name: 'Eurozone', currencySymbol: '€'),
    CountryInfo(code: 'IN', name: 'India', currencySymbol: '₹'),
    CountryInfo(code: 'CA', name: 'Canada', currencySymbol: '\$'), // CAD
    CountryInfo(code: 'AU', name: 'Australia', currencySymbol: '\$'), // AUD
    CountryInfo(code: 'JP', name: 'Japan', currencySymbol: '¥'),
    CountryInfo(code: 'CH', name: 'Switzerland', currencySymbol: 'CHF'),
  ];

  static String getCurrencyForCountry(String? countryCode) {
    final codeToUse = countryCode ?? defaultCountryCode;
    return availableCountries
        .firstWhere((c) => c.code == codeToUse,
            orElse: () => availableCountries.first)
        .currencySymbol;
  }

  String get currencySymbol => getCurrencyForCountry(selectedCountryCode);

  // --- Constructor ---
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode,
    this.paletteIdentifier = defaultPaletteIdentifier, // Use renamed default
    this.uiMode = defaultUIMode,
    this.selectedCountryCode = defaultCountryCode,
    this.isAppLockEnabled = defaultAppLockEnabled,
    this.errorMessage,
    this.packageInfoStatus = PackageInfoStatus.initial,
    this.appVersion,
    this.packageInfoError,
    this.dataManagementStatus = DataManagementStatus.initial,
    this.dataManagementMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    String? paletteIdentifier, // RENAMED
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
      paletteIdentifier: paletteIdentifier ?? this.paletteIdentifier, // RENAMED
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

  @override
  List<Object?> get props => [
        status,
        themeMode,
        paletteIdentifier, // RENAMED
        uiMode,
        selectedCountryCode,
        currencySymbol,
        isAppLockEnabled,
        errorMessage,
        packageInfoStatus,
        appVersion,
        packageInfoError,
        dataManagementStatus,
        dataManagementMessage,
      ];
}
