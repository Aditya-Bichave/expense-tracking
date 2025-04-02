part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateTheme extends SettingsEvent {
  final ThemeMode newMode;

  const UpdateTheme(this.newMode);

  @override
  List<Object?> get props => [newMode];
}

class UpdateCurrency extends SettingsEvent {
  final String newSymbol;

  const UpdateCurrency(this.newSymbol);

  @override
  List<Object?> get props => [newSymbol];
}

class UpdateAppLock extends SettingsEvent {
  final bool isEnabled;

  const UpdateAppLock(this.isEnabled);

  @override
  List<Object?> get props => [isEnabled];
}
