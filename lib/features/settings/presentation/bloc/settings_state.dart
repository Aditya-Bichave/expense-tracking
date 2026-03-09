// lib/features/settings/presentation/bloc/settings_state.dart
part of 'settings_bloc.dart';

// --- Status Enums ---
enum SettingsStatus { initial, loading, loaded, error }

enum PackageInfoStatus { initial, loading, loaded, error }

// --- UI Mode Enum ---
enum UIMode { elemental, quantum, aether, stitch }

class SettingsState extends Equatable {
  // --- Main settings ---
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String paletteIdentifier;
  final UIMode uiMode;
  final String selectedCountryCode;
  final bool isAppLockEnabled;
  final String? errorMessage;

  // --- Demo Mode ---
  final bool isInDemoMode;

  // --- Skip Setup Flag ---
  final bool setupSkipped;

  // --- Package info ---
  final PackageInfoStatus packageInfoStatus;
  final String? appVersion;
  final String? packageInfoError;

  // --- Static Defaults & Data ---
  static const defaultThemeMode = ThemeMode.system;
  static const defaultPaletteIdentifier = AppTheme.elementalPalette1;
  static const defaultUIMode = UIMode.elemental;
  static const String defaultCountryCode = AppCountries.defaultCountryCode;
  static const bool defaultAppLockEnabled = AppConstants.defaultAppLockEnabled;

  // --- Computed Property ---
  String get currencySymbol =>
      AppCountries.getCurrencyForCountry(selectedCountryCode);

  bool get isSetupCompleted => setupSkipped;

  // --- Constructor ---
  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode,
    this.paletteIdentifier = defaultPaletteIdentifier,
    this.uiMode = defaultUIMode,
    this.selectedCountryCode = defaultCountryCode,
    this.isAppLockEnabled = defaultAppLockEnabled,
    this.errorMessage,
    this.isInDemoMode = false,
    this.setupSkipped = false,
    this.packageInfoStatus = PackageInfoStatus.initial,
    this.appVersion,
    this.packageInfoError,
  });

  // --- copyWith ---
  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    String? paletteIdentifier,
    UIMode? uiMode,
    String? selectedCountryCode,
    bool? isAppLockEnabled,
    ValueGetter<String?>? errorMessage,
    bool? isInDemoMode,
    bool? setupSkipped,
    PackageInfoStatus? packageInfoStatus,
    ValueGetter<String?>? appVersion,
    ValueGetter<String?>? packageInfoError,
    bool clearAllMessages = false,
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      paletteIdentifier: paletteIdentifier ?? this.paletteIdentifier,
      uiMode: uiMode ?? this.uiMode,
      selectedCountryCode: selectedCountryCode ?? this.selectedCountryCode,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      errorMessage: clearAllMessages
          ? null
          : errorMessage != null
          ? errorMessage()
          : this.errorMessage,
      isInDemoMode: isInDemoMode ?? this.isInDemoMode,
      setupSkipped: setupSkipped ?? this.setupSkipped,
      packageInfoStatus: packageInfoStatus ?? this.packageInfoStatus,
      appVersion: appVersion != null ? appVersion() : this.appVersion,
      packageInfoError: clearAllMessages
          ? null
          : packageInfoError != null
          ? packageInfoError()
          : this.packageInfoError,
    );
  }

  // --- props ---
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
    isInDemoMode,
    setupSkipped,
    packageInfoStatus,
    appVersion,
    packageInfoError,
  ];
}
