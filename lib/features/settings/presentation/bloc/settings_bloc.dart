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
import 'package:expense_tracker/core/theme/app_theme.dart'; // Import AppTheme
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:expense_tracker/main.dart'; // Import logger

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
    on<UpdateThemeIdentifier>(_onUpdateThemeIdentifier);
    on<UpdateUIMode>(_onUpdateUIMode); // --- ADDED: UI Mode handler ---
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
      log.info("[SettingsBloc] Fetching PackageInfo...");
      packageInfo = await PackageInfo.fromPlatform();
      log.info(
          "[SettingsBloc] PackageInfo fetched: ${packageInfo.version}+${packageInfo.buildNumber}");
    } catch (e, s) {
      packageInfoLoadError = 'Failed to load app version.';
      log.severe("[SettingsBloc] Failed to load PackageInfo$e$s");
    }

    // Fetch settings concurrently
    ThemeMode loadedThemeMode = SettingsState.defaultThemeMode;
    String loadedThemeIdentifier = SettingsState.defaultThemeIdentifier;
    UIMode loadedUIMode = SettingsState.defaultUIMode; // --- ADDED ---
    String? loadedCountryCode = SettingsState.defaultCountryCode;
    bool loadedLock = SettingsState.defaultAppLockEnabled;
    String? settingsLoadError;

    try {
      log.info("[SettingsBloc] Fetching settings from repository...");
      final results = await Future.wait([
        _settingsRepository.getThemeMode(),
        _settingsRepository.getThemeIdentifier(),
        _settingsRepository.getUIMode(), // --- ADDED: Fetch UI Mode ---
        _settingsRepository.getSelectedCountryCode(),
        _settingsRepository.getAppLockEnabled(),
      ]);

      final themeModeResult = results[0] as Either<Failure, ThemeMode>;
      final themeIdResult = results[1] as Either<Failure, String>;
      final uiModeResult =
          results[2] as Either<Failure, UIMode>; // --- ADDED ---
      final countryResult = results[3] as Either<Failure, String?>;
      final appLockResult = results[4] as Either<Failure, bool>;

      themeModeResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (mode) => loadedThemeMode = mode,
      );
      themeIdResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (id) => loadedThemeIdentifier = id,
      );
      // --- ADDED: Handle UI Mode result ---
      uiModeResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (mode) => loadedUIMode = mode,
      );
      // --- END ADDED ---
      countryResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (code) => loadedCountryCode =
            code ?? SettingsState.defaultCountryCode, // Use default if null
      );
      appLockResult.fold(
        (f) => settingsLoadError = _appendError(settingsLoadError, f.message),
        (enabled) => loadedLock = enabled,
      );

      log.info(
          "[SettingsBloc] Settings fetch complete. Errors: $settingsLoadError");

      // --- Emit final combined state ---
      emit(state.copyWith(
        status: settingsLoadError != null
            ? SettingsStatus.error
            : SettingsStatus.loaded,
        errorMessage: settingsLoadError,
        themeMode: loadedThemeMode,
        selectedThemeIdentifier: loadedThemeIdentifier,
        uiMode: loadedUIMode, // --- ADDED ---
        selectedCountryCode: loadedCountryCode,
        // currencySymbol derived in state getter
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
          clearAllMessages: true, // Clear other messages
        ));
      },
      (_) {
        log.info("[SettingsBloc] Theme mode saved. Emitting new state.");
        emit(state.copyWith(
          themeMode: event.newMode,
          status: SettingsStatus.loaded,
          clearAllMessages: true, // Clear other messages
        ));
      },
    );
  }

  Future<void> _onUpdateThemeIdentifier(
      UpdateThemeIdentifier event, Emitter<SettingsState> emit) async {
    log.info(
        "[SettingsBloc] Received UpdateThemeIdentifier event: ${event.newIdentifier}");
    final result =
        await _settingsRepository.saveThemeIdentifier(event.newIdentifier);
    result.fold(
      (failure) {
        log.warning(
            "[SettingsBloc] Failed to save theme identifier: ${failure.message}");
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: failure.message,
          clearAllMessages: true,
        ));
      },
      (_) {
        log.info("[SettingsBloc] Theme identifier saved. Emitting new state.");
        emit(state.copyWith(
          selectedThemeIdentifier: event.newIdentifier,
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
      },
    );
  }

  // --- ADDED: UI Mode Handler ---
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
        emit(state.copyWith(
          uiMode: event.newMode,
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
        // Note: We might need a DataChangedEvent for settings if UI structure changes drastically later
        // publishDataChangedEvent(type: DataChangeType.settings, reason: DataChangeReason.updated);
      },
    );
  }
  // --- END ADDED ---

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
        // No need to save currency symbol, it's derived
        emit(state.copyWith(
          selectedCountryCode: event.newCountryCode,
          status: SettingsStatus.loaded,
          clearAllMessages: true,
        ));
        // Publish settings change event so lists using currency formatter update
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
        // Publish events to trigger full refresh in other Blocs
        publishDataChangedEvent(
            type: DataChangeType.account, reason: DataChangeReason.added);
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.added);
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.added);
        // Also trigger settings reload to reflect potentially restored settings (if included in future)
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
        // Publish events to trigger refresh/clear in other Blocs
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
