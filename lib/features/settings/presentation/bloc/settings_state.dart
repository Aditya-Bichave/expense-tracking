part of 'settings_bloc.dart';

// --- Status Enums ---
enum SettingsStatus { initial, loading, loaded, error }

enum PackageInfoStatus { initial, loading, loaded, error }

enum DataManagementStatus { initial, loading, success, error }

// --- Country Info Helper ---
class CountryInfo {
  final String code; // e.g., 'US', 'GB', 'IN'
  final String name; // e.g., 'United States', 'United Kingdom', 'India'
  final String currencySymbol; // e.g., '$', '£', '₹'
  // Add flag asset path or emoji if desired

  const CountryInfo(
      {required this.code, required this.name, required this.currencySymbol});

  // Make code the equality comparison point
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
  final String
      selectedThemeIdentifier; // ID for the chosen theme (e.g., 'pastelPeach')
  final String selectedCountryCode; // e.g., 'US', 'IN'
  // currencySymbol is now a getter based on selectedCountryCode
  final bool isAppLockEnabled;
  final String? errorMessage; // Error for main settings loading/saving

  // --- Package info ---
  final PackageInfoStatus packageInfoStatus;
  final String? appVersion;
  final String? packageInfoError;

  // --- Data Management ---
  final DataManagementStatus dataManagementStatus;
  final String? dataManagementMessage; // For success/error feedback

  // --- Static Defaults & Data ---
  static const defaultThemeMode = ThemeMode.system;
  static const defaultThemeIdentifier = AppTheme.defaultThemeId;
  static const defaultCountryCode = 'US'; // Default country
  static const defaultAppLockEnabled = false;

  // Define country list and currency map
  static const List<CountryInfo> availableCountries = [
    CountryInfo(code: 'US', name: 'United States', currencySymbol: '\$'),
    CountryInfo(code: 'GB', name: 'United Kingdom', currencySymbol: '£'),
    CountryInfo(
        code: 'EU',
        name: 'Eurozone',
        currencySymbol: '€'), // Represent Eurozone
    CountryInfo(code: 'IN', name: 'India', currencySymbol: '₹'),
    CountryInfo(code: 'CA', name: 'Canada', currencySymbol: '\$'), // CAD
    CountryInfo(code: 'AU', name: 'Australia', currencySymbol: '\$'), // AUD
    CountryInfo(code: 'JP', name: 'Japan', currencySymbol: '¥'),
    CountryInfo(code: 'CH', name: 'Switzerland', currencySymbol: 'CHF'),
    // Add more countries as needed
  ];

  // Helper to get currency symbol based on country code
  static String getCurrencyForCountry(String? countryCode) {
    final codeToUse = countryCode ?? defaultCountryCode; // Use default if null
    return availableCountries
        .firstWhere((c) => c.code == codeToUse,
            orElse: () => availableCountries.first) // Fallback to first country
        .currencySymbol;
  }

  // Getter for the derived currency symbol
  String get currencySymbol => getCurrencyForCountry(selectedCountryCode);

  // --- Constructor ---
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode,
    this.selectedThemeIdentifier = defaultThemeIdentifier,
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
    String? selectedThemeIdentifier,
    String? selectedCountryCode,
    bool? isAppLockEnabled,
    String? errorMessage,
    PackageInfoStatus? packageInfoStatus,
    String? appVersion,
    String? packageInfoError,
    DataManagementStatus? dataManagementStatus,
    String? dataManagementMessage,
    // Helper flags to clear specific messages/errors on update
    bool clearMainError = false,
    bool clearPackageInfoError = false,
    bool clearDataManagementMessage = false,
    bool clearAllMessages = false, // Convenience flag
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      selectedThemeIdentifier:
          selectedThemeIdentifier ?? this.selectedThemeIdentifier,
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
        selectedThemeIdentifier, // Use identifier in props
        selectedCountryCode, // Use country code in props
        currencySymbol, // Include derived symbol in props for changes
        isAppLockEnabled,
        errorMessage,
        packageInfoStatus,
        appVersion,
        packageInfoError,
        dataManagementStatus,
        dataManagementMessage,
      ];
}
