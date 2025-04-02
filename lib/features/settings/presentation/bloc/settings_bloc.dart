import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart'; // For NoParams
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart'; // Import UseCase
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart'; // Import UseCase
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart'; // Import UseCase
import 'package:expense_tracker/core/di/service_locator.dart'; // Import sl & publish helper
import 'package:expense_tracker/core/events/data_change_event.dart'; // Import event
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  // --- Inject Data Management Use Cases ---
  final BackupDataUseCase _backupDataUseCase;
  final RestoreDataUseCase _restoreDataUseCase;
  final ClearAllDataUseCase _clearAllDataUseCase;
  // ----------------------------------------

  SettingsBloc({
    required SettingsRepository settingsRepository,
    // --- Add Use Cases to constructor ---
    required BackupDataUseCase backupDataUseCase,
    required RestoreDataUseCase restoreDataUseCase,
    required ClearAllDataUseCase clearAllDataUseCase,
    // ------------------------------------
  })  : _settingsRepository = settingsRepository,
        // --- Assign Use Cases ---
        _backupDataUseCase = backupDataUseCase,
        _restoreDataUseCase = restoreDataUseCase,
        _clearAllDataUseCase = clearAllDataUseCase,
        // ------------------------
        super(const SettingsState()) {
    // Existing handlers
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateCurrency>(_onUpdateCurrency);
    on<UpdateAppLock>(_onUpdateAppLock);
    // --- New Data Management Handlers ---
    on<BackupRequested>(_onBackupRequested);
    on<RestoreRequested>(_onRestoreRequested);
    on<ClearDataRequested>(_onClearDataRequested);
    // ------------------------------------
  }

  // --- _onLoadSettings, _onUpdateTheme, etc. remain the same ---
  // (Make sure they reset dataManagementStatus if needed, e.g., in copyWith)
  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    // Emit loading for main settings and package info separately
    emit(state.copyWith(
      status: SettingsStatus.loading,
      packageInfoStatus: PackageInfoStatus.loading,
      dataManagementStatus:
          DataManagementStatus.initial, // Reset DM status on load
      clearMainError: true,
      clearPackageInfoError: true,
      clearDataManagementMessage: true,
    ));
    // ... rest of _onLoadSettings implementation from previous step ...
    // Fetch Package Info Concurrently
    PackageInfo? packageInfo;
    String? packageInfoLoadError;
    try {
      packageInfo = await PackageInfo.fromPlatform();
      // Don't emit here yet, combine at the end
    } catch (e) {
      packageInfoLoadError = 'Failed to load app version: $e';
    }

    // Fetch other settings concurrently
    ThemeMode loadedTheme = state.themeMode;
    String? loadedSymbol = SettingsState.defaultCurrencySymbol;
    bool loadedLock = state.isAppLockEnabled;
    String? settingsLoadError;

    try {
      final results = await Future.wait([
        _settingsRepository.getThemeMode(),
        _settingsRepository.getCurrencySymbol(),
        _settingsRepository.getAppLockEnabled(),
      ]);

      final themeResult = results[0] as Either<Failure, ThemeMode>;
      final currencyResult = results[1] as Either<Failure, String?>;
      final appLockResult = results[2] as Either<Failure, bool>;

      themeResult.fold(
        (failure) =>
            settingsLoadError = '${settingsLoadError ?? ''}${failure.message} ',
        (themeMode) => loadedTheme = themeMode,
      );

      currencyResult.fold(
        (failure) =>
            settingsLoadError = '${settingsLoadError ?? ''}${failure.message} ',
        (symbol) =>
            loadedSymbol = symbol ?? SettingsState.defaultCurrencySymbol,
      );

      appLockResult.fold(
        (failure) =>
            settingsLoadError = '${settingsLoadError ?? ''}${failure.message} ',
        (isEnabled) => loadedLock = isEnabled,
      );

      // --- Emit final combined state ---
      emit(state.copyWith(
        status: settingsLoadError != null
            ? SettingsStatus.error
            : SettingsStatus.loaded,
        errorMessage: settingsLoadError?.trim(),
        themeMode: loadedTheme,
        currencySymbol: loadedSymbol,
        isAppLockEnabled: loadedLock,
        packageInfoStatus: packageInfoLoadError != null
            ? PackageInfoStatus.error
            : PackageInfoStatus.loaded,
        packageInfoError: packageInfoLoadError,
        appVersion: packageInfo != null
            ? '${packageInfo.version}+${packageInfo.buildNumber}'
            : null,
      ));
      // ------------------------------
    } catch (e, stackTrace) {
      // Catch unexpected errors during settings fetch
      print("Unexpected error loading main settings: $e\n$stackTrace");
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'An unexpected error occurred loading settings.',
        // Also update package info status if it was loading
        packageInfoStatus: state.packageInfoStatus == PackageInfoStatus.loading
            ? PackageInfoStatus.error
            : state.packageInfoStatus,
        packageInfoError: state.packageInfoStatus == PackageInfoStatus.loading
            ? 'Failed due to main settings error'
            : state.packageInfoError,
      ));
    }
  }

  Future<void> _onUpdateTheme(
      UpdateTheme event, Emitter<SettingsState> emit) async {
    final result = await _settingsRepository.saveThemeMode(event.newMode);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
        dataManagementStatus: DataManagementStatus.initial, // Reset
        clearDataManagementMessage: true,
        clearPackageInfoError: true,
      )),
      (_) => emit(state.copyWith(
        themeMode: event.newMode,
        status: SettingsStatus.loaded,
        dataManagementStatus: DataManagementStatus.initial, // Reset
        clearMainError: true,
        clearDataManagementMessage: true,
        clearPackageInfoError: true,
      )),
    );
  }

  Future<void> _onUpdateCurrency(
      UpdateCurrency event, Emitter<SettingsState> emit) async {
    final result =
        await _settingsRepository.saveCurrencySymbol(event.newSymbol);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
        dataManagementStatus: DataManagementStatus.initial, // Reset
        clearDataManagementMessage: true,
        clearPackageInfoError: true,
      )),
      (_) => emit(state.copyWith(
        currencySymbol: event.newSymbol,
        status: SettingsStatus.loaded,
        dataManagementStatus: DataManagementStatus.initial, // Reset
        clearMainError: true,
        clearDataManagementMessage: true,
        clearPackageInfoError: true,
      )),
    );
  }

  Future<void> _onUpdateAppLock(
      UpdateAppLock event, Emitter<SettingsState> emit) async {
    final result =
        await _settingsRepository.saveAppLockEnabled(event.isEnabled);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
        dataManagementStatus: DataManagementStatus.initial, // Reset
        clearDataManagementMessage: true,
        clearPackageInfoError: true,
      )),
      (_) => emit(state.copyWith(
        isAppLockEnabled: event.isEnabled,
        status: SettingsStatus.loaded,
        dataManagementStatus: DataManagementStatus.initial, // Reset
        clearMainError: true,
        clearDataManagementMessage: true,
        clearPackageInfoError: true,
      )),
    );
  }

  Future<void> _onBackupRequested(
      BackupRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(
        dataManagementStatus: DataManagementStatus.loading,
        clearDataManagementMessage: true));
    final result = await _backupDataUseCase(NoParams());
    result.fold(
        (failure) => emit(state.copyWith(
            dataManagementStatus: DataManagementStatus.error,
            dataManagementMessage: 'Backup failed: ${failure.message}')),
        (messageOrPath) {
      // Result is either path (non-web) or message (web)
      String successMessage;
      if (kIsWeb) {
        successMessage = messageOrPath ??
            'Backup download initiated!'; // Default web message
      } else {
        successMessage =
            'Backup successful! Saved to: ${messageOrPath ?? 'chosen location'}';
      }
      emit(state.copyWith(
          dataManagementStatus: DataManagementStatus.success,
          dataManagementMessage: successMessage));
    });
  }

  Future<void> _onRestoreRequested(
      RestoreRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(
        dataManagementStatus: DataManagementStatus.loading,
        clearDataManagementMessage: true));
    final result =
        await _restoreDataUseCase(NoParams()); // UseCase handles file picking
    result.fold(
      (failure) => emit(state.copyWith(
          dataManagementStatus: DataManagementStatus.error,
          dataManagementMessage: 'Restore failed: ${failure.message}')),
      (_) {
        emit(state.copyWith(
            dataManagementStatus: DataManagementStatus.success,
            dataManagementMessage: 'Restore successful!'));
        // Publish event to trigger refresh in other Blocs
        publishDataChangedEvent(
            type: DataChangeType.account,
            reason: DataChangeReason.added); // Use added to signal full reload
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.added);
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.added);
      },
    );
  }

  Future<void> _onClearDataRequested(
      ClearDataRequested event, Emitter<SettingsState> emit) async {
    emit(state.copyWith(
        dataManagementStatus: DataManagementStatus.loading,
        clearDataManagementMessage: true));
    final result = await _clearAllDataUseCase(NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
          dataManagementStatus: DataManagementStatus.error,
          dataManagementMessage: 'Failed to clear data: ${failure.message}')),
      (_) {
        emit(state.copyWith(
            dataManagementStatus: DataManagementStatus.success,
            dataManagementMessage: 'All data cleared successfully!'));
        // Publish event to trigger refresh in other Blocs
        publishDataChangedEvent(
            type: DataChangeType.account,
            reason: DataChangeReason.deleted); // Use deleted to signal clear
        publishDataChangedEvent(
            type: DataChangeType.expense, reason: DataChangeReason.deleted);
        publishDataChangedEvent(
            type: DataChangeType.income, reason: DataChangeReason.deleted);
      },
    );
  }
  // -------------------
}
