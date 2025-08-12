// lib/features/settings/presentation/bloc/settings_bloc.dart
import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:simple_logger/simple_logger.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final DemoModeService _demoModeService;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required DemoModeService demoModeService,
  })  : _settingsRepository = settingsRepository,
        _demoModeService = demoModeService,
        super(SettingsState(
          isInDemoMode: demoModeService.isDemoActive,
          setupSkipped: false, // Ensure skip starts false
        )) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdatePaletteIdentifier>(_onUpdatePaletteIdentifier);
    on<UpdateUIMode>(_onUpdateUIMode);
    on<UpdateCountry>(_onUpdateCountry);
    on<UpdateAppLock>(_onUpdateAppLock);
    on<EnterDemoMode>(_onEnterDemoMode);
    on<ExitDemoMode>(_onExitDemoMode);
    on<SkipSetup>(_onSkipSetup); // ADDED Handler
    on<ResetSkipSetupFlag>(_onResetSkipSetupFlag); // ADDED Handler
    on<ClearSettingsMessage>(_onClearMessage);

    log.info("[SettingsBloc] Initialized.");
  }

  // --- Skip Setup Handlers --- ADDED
  void _onSkipSetup(SkipSetup event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Setup skipped flag set.");
    emit(state.copyWith(setupSkipped: true));
  }

  void _onResetSkipSetupFlag(
      ResetSkipSetupFlag event, Emitter<SettingsState> emit) {
    if (state.setupSkipped) {
      log.info("[SettingsBloc] Resetting setup skipped flag.");
      emit(state.copyWith(setupSkipped: false));
    }
  }
  // --- END ADDED ---

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received LoadSettings event.");
    emit(state.copyWith(
      status: SettingsStatus.loading,
      packageInfoStatus: PackageInfoStatus.loading,
      clearAllMessages: true,
      // Ensure flags are reset on a full load (e.g., app start)
      isInDemoMode: false,
      setupSkipped: false,
    ));
    // ... (rest of loading logic unchanged) ...
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
        // Ensure isInDemoMode stays false after loading real settings
        isInDemoMode: false,
        setupSkipped: false, // Ensure skip flag is reset on full load
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
        isInDemoMode: false, // Ensure demo mode is off on error too
        setupSkipped: false, // Ensure skip flag is reset on error too
      ));
    }
  }

  String _appendError(String? currentError, String newMessage) {
    return (currentError == null || currentError.isEmpty)
        ? newMessage
        : '$currentError\n$newMessage';
  }

  // --- Other Event Handlers (Unchanged but added demo checks) ---
  Future<void> _onUpdateTheme(
      UpdateTheme event, Emitter<SettingsState> emit) async {
    if (_demoModeService.isDemoActive) {
      log.warning("[SettingsBloc] Ignoring UpdateTheme in Demo Mode.");
      return;
    }
    // ... rest of handler
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
    });
  }

  Future<void> _onUpdatePaletteIdentifier(
      UpdatePaletteIdentifier event, Emitter<SettingsState> emit) async {
    if (_demoModeService.isDemoActive) {
      log.warning(
          "[SettingsBloc] Ignoring UpdatePaletteIdentifier in Demo Mode.");
      return;
    }
    // ... rest of handler
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
    if (_demoModeService.isDemoActive) {
      log.warning("[SettingsBloc] Ignoring UpdateUIMode in Demo Mode.");
      return;
    }
    // ... rest of handler
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
      final defaultPalette = AppTheme.getDefaultPaletteForMode(event.newMode);
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
    // Currency *can* be changed before entering demo
    // if (_demoModeService.isDemoActive) {
    //   log.warning("[SettingsBloc] Ignoring UpdateCountry in Demo Mode.");
    //   return;
    // }
    // ... rest of handler
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
    if (_demoModeService.isDemoActive) {
      log.warning("[SettingsBloc] Ignoring UpdateAppLock in Demo Mode.");
      return;
    }
    // ... rest of handler
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
    });
  }

  // --- Demo Mode Handlers ---
  void _onEnterDemoMode(EnterDemoMode event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Entering Demo Mode.");
    _demoModeService.enterDemoMode();
    emit(state.copyWith(
        isInDemoMode: true,
        setupSkipped: false)); // Entering demo clears skip flag
    publishDataChangedEvent(
        type: DataChangeType.system, reason: DataChangeReason.updated);
  }

  void _onExitDemoMode(ExitDemoMode event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Exiting Demo Mode.");
    _demoModeService.exitDemoMode();
    emit(state.copyWith(
        isInDemoMode: false,
        setupSkipped: false)); // Exiting demo clears skip flag
    publishDataChangedEvent(
        type: DataChangeType.system, reason: DataChangeReason.reset);
  }

  void _onClearMessage(
      ClearSettingsMessage event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Clearing settings message.");
    emit(state.copyWith(clearErrorMessage: true));
  }
}
