import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/settings/domain/usecases/toggle_app_lock.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/data/countries.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // For publishDataChangedEvent
import 'package:expense_tracker/core/events/data_change_event.dart';

part 'settings_event.dart';
part 'settings_state.dart';

// Type alias for ValueGetter if not imported
typedef ValueGetter<T> = T Function();

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final ToggleAppLockUseCase _toggleAppLockUseCase;
  final DemoModeService _demoModeService;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required ToggleAppLockUseCase toggleAppLockUseCase,
    required DemoModeService demoModeService,
  }) : _settingsRepository = settingsRepository,
       _toggleAppLockUseCase = toggleAppLockUseCase,
       _demoModeService = demoModeService,
       super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdatePaletteIdentifier>(_onUpdatePaletteIdentifier);
    on<UpdateUIMode>(_onUpdateUIMode);
    on<UpdateCountry>(_onUpdateCountry);
    on<UpdateAppLock>(_onUpdateAppLock);
    on<ClearSettingsMessage>(_onClearMessage);
    on<EnterDemoMode>(_onEnterDemoMode);
    on<ExitDemoMode>(_onExitDemoMode);
    on<SkipSetup>(_onSkipSetup);
  }

  void _onSkipSetup(SkipSetup event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Skipping setup (marking as completed).");
    emit(state.copyWith(setupSkipped: true));
  }

  Future<void> _onLoadSettings(
    LoadSettings event,
    Emitter<SettingsState> emit,
  ) async {
    emit(
      state.copyWith(
        status: SettingsStatus.loading,
        packageInfoStatus: PackageInfoStatus.loading,
        clearAllMessages: true,
      ),
    );
    try {
      log.info("[SettingsBloc] Loading settings and package info...");

      // Load Package Info
      PackageInfo? packageInfo;
      String? packageInfoLoadError;
      try {
        packageInfo = await PackageInfo.fromPlatform();
      } catch (e) {
        log.warning("[SettingsBloc] Failed to load package info: $e");
        packageInfoLoadError = "Failed to load app version";
      }

      // Load Settings individually
      ThemeMode loadedThemeMode = SettingsState.defaultThemeMode;
      String loadedPaletteIdentifier = SettingsState.defaultPaletteIdentifier;
      UIMode loadedUIMode = SettingsState.defaultUIMode;
      String loadedCountryCode = SettingsState.defaultCountryCode;
      bool loadedLock = SettingsState.defaultAppLockEnabled;
      String? settingsLoadError;

      // Theme
      final themeResult = await _settingsRepository.getThemeMode();
      themeResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (mode) => loadedThemeMode = mode,
      );

      // Palette
      final paletteResult = await _settingsRepository.getPaletteIdentifier();
      paletteResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (id) => loadedPaletteIdentifier = id,
      );

      // UI Mode
      final uiResult = await _settingsRepository.getUIMode();
      uiResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (mode) => loadedUIMode = mode,
      );

      // Country
      final countryResult = await _settingsRepository.getSelectedCountryCode();
      countryResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (code) => loadedCountryCode = code ?? SettingsState.defaultCountryCode,
      );

      // App Lock
      final lockResult = await _settingsRepository.getAppLockEnabled();
      lockResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (enabled) => loadedLock = enabled,
      );

      emit(
        state.copyWith(
          status: settingsLoadError != null
              ? SettingsStatus.error
              : SettingsStatus.loaded,
          errorMessage: () => settingsLoadError,
          themeMode: loadedThemeMode,
          paletteIdentifier: loadedPaletteIdentifier,
          uiMode: loadedUIMode,
          selectedCountryCode: loadedCountryCode,
          isAppLockEnabled: loadedLock,
          packageInfoStatus: packageInfoLoadError != null
              ? PackageInfoStatus.error
              : PackageInfoStatus.loaded,
          packageInfoError: () => packageInfoLoadError,
          appVersion: () => packageInfo != null
              ? '${packageInfo.version}+${packageInfo.buildNumber}'
              : null,
          isInDemoMode: false,
          setupSkipped: false,
        ),
      );
      log.info("[SettingsBloc] Emitted final loaded/error state.");
    } catch (e, s) {
      log.severe("[SettingsBloc] Unexpected error loading settings$e$s");
      emit(
        state.copyWith(
          status: SettingsStatus.error,
          errorMessage: () => 'An unexpected error occurred loading settings.',
          packageInfoStatus:
              state.packageInfoStatus == PackageInfoStatus.loading
              ? PackageInfoStatus.error
              : state.packageInfoStatus,
          packageInfoError: () =>
              state.packageInfoStatus == PackageInfoStatus.loading
              ? 'Failed due to main settings error'
              : state.packageInfoError,
          isInDemoMode: false,
          setupSkipped: false,
        ),
      );
    }
  }

  String _appendError(String? currentError, String newMessage) {
    return (currentError == null || currentError.isEmpty)
        ? newMessage
        : '$currentError\n$newMessage';
  }

  Future<void> _onUpdateTheme(
    UpdateTheme event,
    Emitter<SettingsState> emit,
  ) async {
    if (_demoModeService.isDemoActive) {
      log.warning("[SettingsBloc] Ignoring UpdateTheme in Demo Mode.");
      return;
    }
    log.info(
      "[SettingsBloc] Received UpdateTheme event: ${event.newMode.name}",
    );
    final result = await _settingsRepository.saveThemeMode(event.newMode);
    result.fold(
      (failure) {
        log.warning(
          "[SettingsBloc] Failed to save theme mode: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: SettingsStatus.error,
            errorMessage: () => failure.message,
            clearAllMessages: true,
          ),
        );
      },
      (_) {
        log.info("[SettingsBloc] Theme mode saved. Emitting new state.");
        emit(
          state.copyWith(
            themeMode: event.newMode,
            status: SettingsStatus.loaded,
            clearAllMessages: true,
          ),
        );
      },
    );
  }

  Future<void> _onUpdatePaletteIdentifier(
    UpdatePaletteIdentifier event,
    Emitter<SettingsState> emit,
  ) async {
    if (_demoModeService.isDemoActive) {
      log.warning(
        "[SettingsBloc] Ignoring UpdatePaletteIdentifier in Demo Mode.",
      );
      return;
    }
    log.info(
      "[SettingsBloc] Received UpdatePaletteIdentifier event: ${event.newIdentifier}",
    );
    final result = await _settingsRepository.savePaletteIdentifier(
      event.newIdentifier,
    );
    result.fold(
      (failure) {
        log.warning(
          "[SettingsBloc] Failed to save palette identifier: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: SettingsStatus.error,
            errorMessage: () => failure.message,
            clearAllMessages: true,
          ),
        );
      },
      (_) {
        log.info(
          "[SettingsBloc] Palette identifier saved. Emitting new state.",
        );
        emit(
          state.copyWith(
            paletteIdentifier: event.newIdentifier,
            status: SettingsStatus.loaded,
            clearAllMessages: true,
          ),
        );
        publishDataChangedEvent(
          type: DataChangeType.settings,
          reason: DataChangeReason.updated,
        );
      },
    );
  }

  Future<void> _onUpdateUIMode(
    UpdateUIMode event,
    Emitter<SettingsState> emit,
  ) async {
    if (_demoModeService.isDemoActive) {
      log.warning("[SettingsBloc] Ignoring UpdateUIMode in Demo Mode.");
      return;
    }
    log.info(
      "[SettingsBloc] Received UpdateUIMode event: ${event.newMode.name}",
    );
    final result = await _settingsRepository.saveUIMode(event.newMode);
    await result.fold(
      (failure) {
        log.warning(
          "[SettingsBloc] Failed to save UI mode: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: SettingsStatus.error,
            errorMessage: () => failure.message,
            clearAllMessages: true,
          ),
        );
      },
      (_) async {
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
          case UIMode.stitch:
            defaultPalette = AppTheme.stitchPalette1;
            break;
        }
        log.info("[SettingsBloc] Saving default palette: $defaultPalette");
        _settingsRepository.savePaletteIdentifier(defaultPalette);

        emit(
          state.copyWith(
            uiMode: event.newMode,
            paletteIdentifier: defaultPalette,
            status: SettingsStatus.loaded,
            clearAllMessages: true,
          ),
        );
        publishDataChangedEvent(
          type: DataChangeType.settings,
          reason: DataChangeReason.updated,
        );
      },
    );
  }

  Future<void> _onUpdateCountry(
    UpdateCountry event,
    Emitter<SettingsState> emit,
  ) async {
    log.info(
      "[SettingsBloc] Received UpdateCountry event: ${event.newCountryCode}",
    );
    final result = await _settingsRepository.saveSelectedCountryCode(
      event.newCountryCode,
    );
    result.fold(
      (failure) {
        log.warning(
          "[SettingsBloc] Failed to save country code: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: SettingsStatus.error,
            errorMessage: () => failure.message,
            clearAllMessages: true,
          ),
        );
      },
      (_) {
        log.info("[SettingsBloc] Country code saved. Emitting new state.");
        emit(
          state.copyWith(
            selectedCountryCode: event.newCountryCode,
            status: SettingsStatus.loaded,
            clearAllMessages: true,
          ),
        );
        publishDataChangedEvent(
          type: DataChangeType.settings,
          reason: DataChangeReason.updated,
        );
      },
    );
  }

  Future<void> _onUpdateAppLock(
    UpdateAppLock event,
    Emitter<SettingsState> emit,
  ) async {
    if (_demoModeService.isDemoActive) {
      log.warning("[SettingsBloc] Ignoring UpdateAppLock in Demo Mode.");
      return;
    }
    emit(
      state.copyWith(status: SettingsStatus.loading, clearAllMessages: true),
    );
    log.info("[SettingsBloc] Received UpdateAppLock event: ${event.isEnabled}");
    final result = await _toggleAppLockUseCase(event.isEnabled);
    result.fold(
      (failure) {
        log.warning(
          "[SettingsBloc] Failed to save app lock setting: ${failure.message}",
        );
        emit(
          state.copyWith(
            status: SettingsStatus.error,
            errorMessage: () => failure.message,
            clearAllMessages: true,
          ),
        );
      },
      (_) {
        log.info("[SettingsBloc] App lock setting saved. Emitting new state.");
        emit(
          state.copyWith(
            isAppLockEnabled: event.isEnabled,
            status: SettingsStatus.loaded,
            clearAllMessages: true,
          ),
        );
      },
    );
  }

  void _onEnterDemoMode(EnterDemoMode event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Entering Demo Mode.");
    _demoModeService.enterDemoMode();
    emit(state.copyWith(isInDemoMode: true, setupSkipped: false));
    publishDataChangedEvent(
      type: DataChangeType.system,
      reason: DataChangeReason.reset,
    );
  }

  void _onExitDemoMode(ExitDemoMode event, Emitter<SettingsState> emit) {
    log.info("[SettingsBloc] Exiting Demo Mode.");
    _demoModeService.exitDemoMode();
    emit(state.copyWith(isInDemoMode: false, setupSkipped: false));
    publishDataChangedEvent(
      type: DataChangeType.system,
      reason: DataChangeReason.reset,
    );
  }

  void _onClearMessage(
    ClearSettingsMessage event,
    Emitter<SettingsState> emit,
  ) {
    log.info("[SettingsBloc] Clearing settings message.");
    emit(state.copyWith(errorMessage: () => null));
  }
}
