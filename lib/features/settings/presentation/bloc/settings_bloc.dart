import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:expense_tracker/main.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  final BackupDataUseCase _backupDataUseCase;
  final RestoreDataUseCase _restoreDataUseCase;
  final ClearAllDataUseCase _clearAllDataUseCase;

  SettingsBloc({
    required SettingsRepository settingsRepository,
    required BackupDataUseCase backupDataUseCase,
    required RestoreDataUseCase restoreDataUseCase,
    required ClearAllDataUseCase clearAllDataUseCase,
  })  : _settingsRepository = settingsRepository,
        _backupDataUseCase = backupDataUseCase,
        _restoreDataUseCase = restoreDataUseCase,
        _clearAllDataUseCase = clearAllDataUseCase,
        super(const SettingsState()) {
    // Settings handlers
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdatePaletteIdentifier>(_onUpdatePaletteIdentifier); // RENAMED
    on<UpdateUIMode>(_onUpdateUIMode);
    on<UpdateCountry>(_onUpdateCountry);
    on<UpdateAppLock>(_onUpdateAppLock);
    // Data Management Handlers
    on<BackupRequested>(_onBackupRequested);
    on<RestoreRequested>(_onRestoreRequested);
    on<ClearDataRequested>(_onClearDataRequested);
    log.info("[SettingsBloc] Initialized.");
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received LoadSettings event.");
    emit(state.copyWith(
      status: SettingsStatus.loading,
      packageInfoStatus: PackageInfoStatus.loading,
      dataManagementStatus: DataManagementStatus.initial,
      clearAllMessages: true,
    ));

    PackageInfo? packageInfo;
    String? packageInfoLoadError;
    try {
      // log.info("[SettingsBloc] Fetching PackageInfo..."); // Log less noise
      packageInfo = await PackageInfo.fromPlatform();
      // log.info("[SettingsBloc] PackageInfo fetched: ${packageInfo.version}+${packageInfo.buildNumber}");
    } catch (e, s) {
      packageInfoLoadError = 'Failed to load app version.';
      log.severe("[SettingsBloc] Failed to load PackageInfo$e$s");
    }

    // Fetch settings concurrently
    ThemeMode loadedThemeMode = SettingsState.defaultThemeMode;
    String loadedPaletteIdentifier =
        SettingsState.defaultPaletteIdentifier; // RENAMED
    UIMode loadedUIMode = SettingsState.defaultUIMode;
    String? loadedCountryCode = SettingsState.defaultCountryCode;
    bool loadedLock = SettingsState.defaultAppLockEnabled;
    String? settingsLoadError;

    try {
      // log.info("[SettingsBloc] Fetching settings from repository..."); // Log less noise
      final results = await Future.wait([
        _settingsRepository.getThemeMode(),
        _settingsRepository.getPaletteIdentifier(), // RENAMED
        _settingsRepository.getUIMode(),
        _settingsRepository.getSelectedCountryCode(),
        _settingsRepository.getAppLockEnabled(),
      ]);

      final themeModeResult = results[0] as Either<Failure, ThemeMode>;
      final paletteIdResult = results[1] as Either<Failure, String>; // RENAMED
      final uiModeResult = results[2] as Either<Failure, UIMode>;
      final countryResult = results[3] as Either<Failure, String?>;
      final appLockResult = results[4] as Either<Failure, bool>;

      themeModeResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (mode) => loadedThemeMode = mode,
      );
      paletteIdResult.fold(
        // RENAMED
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (id) => loadedPaletteIdentifier = id, // RENAMED
      );
      uiModeResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (mode) => loadedUIMode = mode,
      );
      countryResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (code) => loadedCountryCode = code ?? SettingsState.defaultCountryCode,
      );
      appLockResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (enabled) => loadedLock = enabled,
      );

      // log.info("[SettingsBloc] Settings fetch complete. Errors: $settingsLoadError"); // Log less noise

      emit(state.copyWith(
        status: settingsLoadError != null
            ? SettingsStatus.error
            : SettingsStatus.loaded,
        errorMessage: settingsLoadError,
        themeMode: loadedThemeMode,
        paletteIdentifier: loadedPaletteIdentifier, // RENAMED
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
    result.fold(
      (failure) {
        log.warning(
            "[SettingsBloc] Failed to save theme mode: ${failure.message}");
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true,
        ));
      },
      (_) {
        log.info("[SettingsBloc] Theme mode saved. Emitting new state.");
        emit(state.copyWith(
          themeMode: event.newMode,
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
      },
    );
  }

  Future<void> _onUpdatePaletteIdentifier(
      // RENAMED
      UpdatePaletteIdentifier event,
      Emitter<SettingsState> emit) async {
    // RENAMED
    log.info(
        "[SettingsBloc] Received UpdatePaletteIdentifier event: ${event.newIdentifier}"); // RENAMED
    final result = await _settingsRepository
        .savePaletteIdentifier(event.newIdentifier); // RENAMED
    result.fold(
      (failure) {
        log.warning(
            "[SettingsBloc] Failed to save palette identifier: ${failure.message}"); // RENAMED
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true,
        ));
      },
      (_) {
        log.info(
            "[SettingsBloc] Palette identifier saved. Emitting new state."); // RENAMED
        emit(state.copyWith(
          paletteIdentifier: event.newIdentifier, // RENAMED
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
      },
    );
  }

  Future<void> _onUpdateUIMode(
      UpdateUIMode event, Emitter<SettingsState> emit) async {
    log.info(
        "[SettingsBloc] Received UpdateUIMode event: ${event.newMode.name}");
    final result = await _settingsRepository.saveUIMode(event.newMode);
    result.fold(
      (failure) {
        log.warning(
            "[SettingsBloc] Failed to save UI mode: ${failure.message}");
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true,
        ));
      },
      (_) {
        log.info("[SettingsBloc] UI mode saved. Emitting new state.");
        // Determine the default palette for the new UI mode
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
        log.info(
            "[SettingsBloc] Setting default palette for new UI mode to: $defaultPalette");
        // Save the default palette for the new mode as well
        _settingsRepository.savePaletteIdentifier(defaultPalette);

        emit(state.copyWith(
          uiMode: event.newMode,
          paletteIdentifier: defaultPalette, // Update palette state too
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
        // Publish settings change event
        publishDataChangedEvent(
            type: DataChangeType.settings, reason: DataChangeReason.updated);
      },
    );
  }

  Future<void> _onUpdateCountry(
      UpdateCountry event, Emitter<SettingsState> emit) async {
    log.info(
        "[SettingsBloc] Received UpdateCountry event: ${event.newCountryCode}");
    final result =
        await _settingsRepository.saveSelectedCountryCode(event.newCountryCode);
    result.fold(
      (failure) {
        log.warning(
            "[SettingsBloc] Failed to save country code: ${failure.message}");
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true,
        ));
      },
      (_) {
        log.info("[SettingsBloc] Country code saved. Emitting new state.");
        emit(state.copyWith(
          selectedCountryCode: event.newCountryCode,
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
        publishDataChangedEvent(
            type: DataChangeType.settings, reason: DataChangeReason.updated);
      },
    );
  }

  Future<void> _onUpdateAppLock(
      UpdateAppLock event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received UpdateAppLock event: ${event.isEnabled}");
    final result =
        await _settingsRepository.saveAppLockEnabled(event.isEnabled);
    result.fold(
      (failure) {
        log.warning(
            "[SettingsBloc] Failed to save app lock setting: ${failure.message}");
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true,
        ));
      },
      (_) {
        log.info("[SettingsBloc] App lock setting saved. Emitting new state.");
        emit(state.copyWith(
          isAppLockEnabled: event.isEnabled,
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
      },
    );
  }

  // --- Data Management Handlers ---
  Future<void> _onBackupRequested(
      BackupRequested event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received BackupRequested event.");
    emit(state.copyWith(
        dataManagementStatus: DataManagementStatus.loading,
        clearDataManagementMessage: true));
    final result = await _backupDataUseCase(const NoParams());
    result.fold((failure) {
      log.warning("[SettingsBloc] Backup failed: ${failure.message}");
      emit(state.copyWith(
          dataManagementStatus: DataManagementStatus.error,
          dataManagementMessage: 'Backup failed: ${failure.message}'));
    }, (messageOrPath) {
      log.info(
          "[SettingsBloc] Backup successful. Message/Path: $messageOrPath");
      String successMessage = kIsWeb
          ? (messageOrPath ?? 'Backup download initiated!')
          : 'Backup successful! Saved to: ${messageOrPath ?? 'chosen location'}';
      emit(state.copyWith(
          dataManagementStatus: DataManagementStatus.success,
          dataManagementMessage: successMessage));
    });
  }

  Future<void> _onRestoreRequested(
      RestoreRequested event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received RestoreRequested event.");
    emit(state.copyWith(
        dataManagementStatus: DataManagementStatus.loading,
        clearDataManagementMessage: true));
    final result = await _restoreDataUseCase(const NoParams());
    result.fold(
      (failure) {
        log.warning("[SettingsBloc] Restore failed: ${failure.message}");
        emit(state.copyWith(
            dataManagementStatus: DataManagementStatus.error,
            dataManagementMessage: 'Restore failed: ${failure.message}'));
      },
      (_) {
        log.info(
            "[SettingsBloc] Restore successful. Publishing data change events.");
        emit(state.copyWith(
            dataManagementStatus: DataManagementStatus.success,
            dataManagementMessage:
                'Restore successful! App will reload data.'));
        publishDataChangedEvent(
            type: DataChangeType.account, reason: DataChangeReason.added);
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.added);
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.added);
        add(const LoadSettings());
      },
    );
  }

  Future<void> _onClearDataRequested(
      ClearDataRequested event, Emitter<SettingsState> emit) async {
    log.info("[SettingsBloc] Received ClearDataRequested event.");
    emit(state.copyWith(
        dataManagementStatus: DataManagementStatus.loading,
        clearDataManagementMessage: true));
    final result = await _clearAllDataUseCase(const NoParams());
    result.fold(
      (failure) {
        log.warning("[SettingsBloc] Clear data failed: ${failure.message}");
        emit(state.copyWith(
            dataManagementStatus: DataManagementStatus.error,
            dataManagementMessage: 'Failed to clear data: ${failure.message}'));
      },
      (_) {
        log.info(
            "[SettingsBloc] Clear data successful. Publishing data change events.");
        emit(state.copyWith(
            dataManagementStatus: DataManagementStatus.success,
            dataManagementMessage: 'All data cleared successfully!'));
        publishDataChangedEvent(
            type: DataChangeType.account, reason: DataChangeReason.deleted);
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.deleted);
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.deleted);
      },
    );
  }
}
