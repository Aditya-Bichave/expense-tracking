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
  final ThemeMode newMode;
  const UpdateTheme(this.newMode);
  @override
  List<Object?> get props => [newMode];
}

class UpdatePaletteIdentifier extends SettingsEvent {
  final String newIdentifier;
  const UpdatePaletteIdentifier(this.newIdentifier);
  @override
  List<Object?> get props => [newIdentifier];
}

class UpdateUIMode extends SettingsEvent {
  final UIMode newMode;
  const UpdateUIMode(this.newMode);
  @override
  List<Object?> get props => [newMode];
}

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

// --- Demo Mode Events ---
class EnterDemoMode extends SettingsEvent {
  const EnterDemoMode();
}

class ExitDemoMode extends SettingsEvent {
  const ExitDemoMode();
}

// --- Skip Setup Events --- ADDED
class SkipSetup extends SettingsEvent {
  const SkipSetup();
}

class ResetSkipSetupFlag extends SettingsEvent {
  const ResetSkipSetupFlag();
}
// --- END ADDED ---

class ClearSettingsMessage extends SettingsEvent {
  const ClearSettingsMessage();
}
