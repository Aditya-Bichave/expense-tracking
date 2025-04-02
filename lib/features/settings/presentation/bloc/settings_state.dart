part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, loaded, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String?
      currencySymbol; // Null allowed if not set, default applied in state
  final bool isAppLockEnabled;
  final String? errorMessage;

  // --- Static Defaults ---
  // Define defaults directly within the class for clarity
  static const defaultThemeMode = ThemeMode.system;
  static const defaultCurrencySymbol =
      'USD'; // Set your desired default currency
  static const defaultAppLockEnabled = false;
  // --- End Static Defaults ---

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = defaultThemeMode, // Use static default here
    this.currencySymbol = defaultCurrencySymbol, // Use static default here
    this.isAppLockEnabled = defaultAppLockEnabled, // Use static default here
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? isAppLockEnabled,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      errorMessage: (status != null && status != SettingsStatus.error)
          ? null
          : errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        themeMode,
        currencySymbol,
        isAppLockEnabled,
        errorMessage,
      ];
}
