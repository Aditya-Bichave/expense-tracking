// lib/features/settings/presentation/bloc/settings_event.dart
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
  /* ... */ final ThemeMode newMode;
  const UpdateTheme(this.newMode);
  @override
  List<Object?> get props => [newMode];
}

class UpdatePaletteIdentifier extends SettingsEvent {
  /* ... */ final String newIdentifier;
  const UpdatePaletteIdentifier(this.newIdentifier);
  @override
  List<Object?> get props => [newIdentifier];
}

class UpdateUIMode extends SettingsEvent {
  /* ... */ final UIMode newMode;
  const UpdateUIMode(this.newMode);
  @override
  List<Object?> get props => [newMode];
}

class UpdateCountry extends SettingsEvent {
  /* ... */ final String newCountryCode;
  const UpdateCountry(this.newCountryCode);
  @override
  List<Object?> get props => [newCountryCode];
}

class UpdateAppLock extends SettingsEvent {
  /* ... */ final bool isEnabled;
  const UpdateAppLock(this.isEnabled);
  @override
  List<Object?> get props => [isEnabled];
}

// --- Data Management Events (REMOVED) ---
// class BackupRequested extends SettingsEvent { const BackupRequested(); }
// class RestoreRequested extends SettingsEvent { const RestoreRequested(); }
// class ClearDataRequested extends SettingsEvent { const ClearDataRequested(); }

// --- ADDED Event to clear settings/package info error messages ---
class ClearSettingsMessage extends SettingsEvent {
  const ClearSettingsMessage();
}
