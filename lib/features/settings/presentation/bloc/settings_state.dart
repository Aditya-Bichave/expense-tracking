part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, loaded, error }

enum PackageInfoStatus { initial, loading, loaded, error }

// --- Add Data Management Status ---
enum DataManagementStatus { initial, loading, success, error }
// ----------------------------------

class SettingsState extends Equatable {
  // Main settings
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String? currencySymbol;
  final bool isAppLockEnabled;
  final String? errorMessage;

  // Package info
  final PackageInfoStatus packageInfoStatus;
  final String? appVersion;
  final String? packageInfoError;

  // --- Data Management Fields ---
  final DataManagementStatus dataManagementStatus;
  final String? dataManagementMessage; // For success/error feedback
  // ------------------------------

  // --- Static Defaults ---
  static const defaultThemeMode = ThemeMode.system;
  static const defaultCurrencySymbol = 'USD';
  static const defaultAppLockEnabled = false;
  // --- End Static Defaults ---

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode,
    this.currencySymbol = defaultCurrencySymbol,
    this.isAppLockEnabled = defaultAppLockEnabled,
    this.errorMessage,
    this.packageInfoStatus = PackageInfoStatus.initial,
    this.appVersion,
    this.packageInfoError,
    // --- Initialize Data Management Fields ---
    this.dataManagementStatus = DataManagementStatus.initial,
    this.dataManagementMessage,
    // ---------------------------------------
  });

  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? isAppLockEnabled,
    String? errorMessage,
    PackageInfoStatus? packageInfoStatus,
    String? appVersion,
    String? packageInfoError,
    // --- Copy Data Management Fields ---
    DataManagementStatus? dataManagementStatus,
    String? dataManagementMessage,
    // -----------------------------------
    bool clearMainError = false,
    bool clearPackageInfoError = false,
    bool clearDataManagementMessage = false, // Helper flag
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      errorMessage: clearMainError ? null : errorMessage ?? this.errorMessage,
      packageInfoStatus: packageInfoStatus ?? this.packageInfoStatus,
      appVersion: appVersion ?? this.appVersion,
      packageInfoError: clearPackageInfoError
          ? null
          : packageInfoError ?? this.packageInfoError,
      // --- Handle Data Management Fields ---
      dataManagementStatus: dataManagementStatus ?? this.dataManagementStatus,
      dataManagementMessage: clearDataManagementMessage
          ? null
          : dataManagementMessage ?? this.dataManagementMessage,
      // -------------------------------------
    );
  }

  @override
  List<Object?> get props => [
        status,
        themeMode,
        currencySymbol,
        isAppLockEnabled,
        errorMessage,
        packageInfoStatus,
        appVersion,
        packageInfoError,
        // --- Add Data Management Fields to props ---
        dataManagementStatus,
        dataManagementMessage,
        // -----------------------------------------
      ];
}
