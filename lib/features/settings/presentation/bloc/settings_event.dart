part of 'settings_bloc.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();

  @override
  List<Object?> get props => [];
}

// --- Main Settings ---

class LoadSettings extends SettingsEvent {
  const LoadSettings();
}

class UpdateTheme extends SettingsEvent {
  final ThemeMode newMode;
  const UpdateTheme(this.newMode);
  @override
  List<Object?> get props => [newMode];
}

// Event for changing the palette / color variant
class UpdatePaletteIdentifier extends SettingsEvent {
  // RENAMED
  final String newIdentifier;
  const UpdatePaletteIdentifier(this.newIdentifier); // RENAMED
  @override
  List<Object?> get props => [newIdentifier];
}

// Event for changing the UI Mode
class UpdateUIMode extends SettingsEvent {
  final UIMode newMode;
  const UpdateUIMode(this.newMode);
  @override
  List<Object?> get props => [newMode];
}

// Event for changing the selected country
class UpdateCountry extends SettingsEvent {
  final String newCountryCode;
  const UpdateCountry(this.newCountryCode);
  @override
  List<Object?> get props => [newCountryCode];
}

class UpdateAppLock extends SettingsEvent {
  final bool isEnabled;
  const UpdateAppLock(this.isEnabled);
  @override
  List<Object?> get props => [isEnabled];
}

// --- Data Management ---

class BackupRequested extends SettingsEvent {
  const BackupRequested();
}

class RestoreRequested extends SettingsEvent {
  const RestoreRequested();
}

class ClearDataRequested extends SettingsEvent {
  const ClearDataRequested();
}
