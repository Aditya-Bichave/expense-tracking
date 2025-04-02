part of 'settings_bloc.dart';

enum SettingsStatus { initial, loading, loaded, error }

class SettingsState extends Equatable {
  final SettingsStatus status;
  final ThemeMode themeMode;
  final String? currencySymbol; // Allow null initially
  final bool isAppLockEnabled;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.themeMode = ThemeMode.system, // Default theme
    this.currencySymbol = 'USD', // Default currency, adjust as needed
    this.isAppLockEnabled = false, // Default lock state
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? isAppLockEnabled,
    String? errorMessage,
    bool forceCurrencySymbolToNull = false, // Helper for clearing
  }) {
    return SettingsState(
      status: status ?? this.status,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: forceCurrencySymbolToNull
          ? null
          : currencySymbol ?? this.currencySymbol,
      isAppLockEnabled: isAppLockEnabled ?? this.isAppLockEnabled,
      errorMessage: errorMessage ?? this.errorMessage,
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
