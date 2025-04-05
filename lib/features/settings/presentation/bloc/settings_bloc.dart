// lib/features/settings/presentation/bloc/settings_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
// REMOVED Data Management Use Case Imports
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

part 'settings_event.dart';
part 'settings_state.dart'; // State file needs adjustment too

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  // REMOVED Data Management Use Cases

  SettingsBloc({
    required SettingsRepository settingsRepository,
    // REMOVED Data Management Use Cases from constructor
  })  : _settingsRepository = settingsRepository,
        // REMOVED Use Case assignments
        super(const SettingsState()) {
    // Initialize with defaults
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdatePaletteIdentifier>(_onUpdatePaletteIdentifier);
    on<UpdateUIMode>(_onUpdateUIMode);
    on<UpdateCountry>(_onUpdateCountry);
    on<UpdateAppLock>(_onUpdateAppLock);
    // REMOVED Data Management Event Handlers
    on<ClearSettingsMessage>(_onClearMessage); // Added event to clear messages

    log.info("[SettingsBloc] Initialized.");
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received LoadSettings event.");
    emit(state.copyWith(
      status: SettingsStatus.loading,
      packageInfoStatus: PackageInfoStatus.loading,
      // REMOVED dataManagementStatus
      clearAllMessages: true,
    ));

    PackageInfo? packageInfo;
    String? packageInfoLoadError;
    try {
      packageInfo = await PackageInfo.fromPlatform();
    } catch (e, s) {
      packageInfoLoadError = 'Failed to load app version.';
      log.severe("[SettingsBloc] Failed to load PackageInfo$e$s");
    }

    ThemeMode loadedThemeMode = SettingsState.defaultThemeMode;
    String loadedPaletteIdentifier = SettingsState.defaultPaletteIdentifier;
    UIMode loadedUIMode = SettingsState.defaultUIMode;
    String loadedCountryCode = SettingsState.defaultCountryCode;
    bool loadedLock = SettingsState.defaultAppLockEnabled;
    String? settingsLoadError;

    try {
      final results = await Future.wait([
        _settingsRepository.getThemeMode(),
        _settingsRepository.getPaletteIdentifier(),
        _settingsRepository.getUIMode(),
        _settingsRepository.getSelectedCountryCode(),
        _settingsRepository.getAppLockEnabled(),
      ]);

      final themeModeResult = results[0] as Either<Failure, ThemeMode>;
      final paletteIdResult = results[1] as Either<Failure, String>;
      final uiModeResult = results[2] as Either<Failure, UIMode>;
      final countryResult = results[3] as Either<Failure, String?>;
      final appLockResult = results[4] as Either<Failure, bool>;

      themeModeResult.fold(
          (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
          (mode) => loadedThemeMode = mode);
      paletteIdResult.fold(
          (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
          (id) => loadedPaletteIdentifier = id);
      uiModeResult.fold(
          (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
          (mode) => loadedUIMode = mode);
      countryResult.fold(
          (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
          (code) =>
              loadedCountryCode = code ?? SettingsState.defaultCountryCode);
      appLockResult.fold(
          (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
          (enabled) => loadedLock = enabled);

      emit(state.copyWith(
        status: settingsLoadError != null
            ? SettingsStatus.error
            : SettingsStatus.loaded,
        errorMessage: settingsLoadError,
        themeMode: loadedThemeMode,
        paletteIdentifier: loadedPaletteIdentifier,
        uiMode: loadedUIMode,
        selectedCountryCode: loadedCountryCode,
        isAppLockEnabled: loadedLock,
        packageInfoStatus: packageInfoLoadError != null
            ? PackageInfoStatus.error
            : PackageInfoStatus.loaded,
        packageInfoError: packageInfoLoadError,
        appVersion: packageInfo != null
            ? '${packageInfo.version}+${packageInfo.buildNumber}'
            : null,
      ));
      log.info("[SettingsBloc] Emitted final loaded/error state.");
    } catch (e, s) {
      log.severe("[SettingsBloc] Unexpected error loading settings$e$s");
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'An unexpected error occurred loading settings.',
        packageInfoStatus: state.packageInfoStatus == PackageInfoStatus.loading
            ? PackageInfoStatus.error
            : state.packageInfoStatus,
        packageInfoError: state.packageInfoStatus == PackageInfoStatus.loading
            ? 'Failed due to main settings error'
            : state.packageInfoError,
      ));
    }
  }

  String _appendError(String? currentError, String newMessage) {
    return (currentError == null || currentError.isEmpty)
        ? newMessage
        : '$currentError\n$newMessage';
  }

  Future<void> _onUpdateTheme(
      UpdateTheme event, Emitter<SettingsState> emit) async {
    log.info(
        "[SettingsBloc] Received UpdateTheme event: ${event.newMode.name}");
    final result = await _settingsRepository.saveThemeMode(event.newMode);
    result.fold((failure) {
      log.warning(
          "[SettingsBloc] Failed to save theme mode: ${failure.message}");
      emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true));
    }, (_) {
      log.info("[SettingsBloc] Theme mode saved. Emitting new state.");
      emit(state.copyWith(
          themeMode: event.newMode,
          status: SettingsStatus.loaded,
          clearAllMessages: true));
      // Publish if needed (though theme mode alone might not require it)
      // publishDataChangedEvent(type: DataChangeType.settings, reason: DataChangeReason.updated);
    });
  }

  Future<void> _onUpdatePaletteIdentifier(
      UpdatePaletteIdentifier event, Emitter<SettingsState> emit) async {
    log.info(
        "[SettingsBloc] Received UpdatePaletteIdentifier event: ${event.newIdentifier}");
    final result =
        await _settingsRepository.savePaletteIdentifier(event.newIdentifier);
    result.fold((failure) {
      log.warning(
          "[SettingsBloc] Failed to save palette identifier: ${failure.message}");
      emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true));
    }, (_) {
      log.info("[SettingsBloc] Palette identifier saved. Emitting new state.");
      emit(state.copyWith(
          paletteIdentifier: event.newIdentifier,
          status: SettingsStatus.loaded,
          clearAllMessages: true));
      publishDataChangedEvent(
          type: DataChangeType.settings, reason: DataChangeReason.updated);
    });
  }

  Future<void> _onUpdateUIMode(
      UpdateUIMode event, Emitter<SettingsState> emit) async {
    log.info(
        "[SettingsBloc] Received UpdateUIMode event: ${event.newMode.name}");
    final result = await _settingsRepository.saveUIMode(event.newMode);
    result.fold((failure) {
      log.warning("[SettingsBloc] Failed to save UI mode: ${failure.message}");
      emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true));
    }, (_) {
      log.info("[SettingsBloc] UI mode saved. Determining default palette.");
      String defaultPalette;
      switch (event.newMode) {
        case UIMode.elemental:
          defaultPalette = AppTheme.elementalPalette1;
          break;
        case UIMode.quantum:
          defaultPalette = AppTheme.quantumPalette1;
          break;
        case UIMode.aether:
          defaultPalette = AppTheme.aetherPalette1;
          break;
      }
      log.info("[SettingsBloc] Saving default palette: $defaultPalette");
      _settingsRepository
          .savePaletteIdentifier(defaultPalette); // Fire and forget is ok here

      emit(state.copyWith(
        uiMode: event.newMode,
        paletteIdentifier: defaultPalette, // Update palette in state too
        status: SettingsStatus.loaded,
        clearAllMessages: true,
      ));
      publishDataChangedEvent(
          type: DataChangeType.settings, reason: DataChangeReason.updated);
    });
  }

  Future<void> _onUpdateCountry(
      UpdateCountry event, Emitter<SettingsState> emit) async {
    log.info(
        "[SettingsBloc] Received UpdateCountry event: ${event.newCountryCode}");
    final result =
        await _settingsRepository.saveSelectedCountryCode(event.newCountryCode);
    result.fold((failure) {
      log.warning(
          "[SettingsBloc] Failed to save country code: ${failure.message}");
      emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true));
    }, (_) {
      log.info("[SettingsBloc] Country code saved. Emitting new state.");
      emit(state.copyWith(
          selectedCountryCode: event.newCountryCode,
          status: SettingsStatus.loaded,
          clearAllMessages: true));
      publishDataChangedEvent(
          type: DataChangeType.settings, reason: DataChangeReason.updated);
    });
  }

  Future<void> _onUpdateAppLock(
      UpdateAppLock event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received UpdateAppLock event: ${event.isEnabled}");
    final result =
        await _settingsRepository.saveAppLockEnabled(event.isEnabled);
    result.fold((failure) {
      log.warning(
          "[SettingsBloc] Failed to save app lock setting: ${failure.message}");
      emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true));
    }, (_) {
      log.info("[SettingsBloc] App lock setting saved. Emitting new state.");
      emit(state.copyWith(
          isAppLockEnabled: event.isEnabled,
          status: SettingsStatus.loaded,
          clearAllMessages: true));
      // No need to publish DataChangedEvent for app lock
    });
  }

  void _onClearMessage(
      ClearSettingsMessage event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Clearing settings message.");
    // Only clear error messages, keep status as loaded/error
    emit(state.copyWith(clearErrorMessage: true));
  }

  // REMOVED Data Management Handlers (_onBackupRequested, _onRestoreRequested, _onClearDataRequested)
}
