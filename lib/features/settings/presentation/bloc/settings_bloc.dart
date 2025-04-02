import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import package_info_plus

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;
  // No need to inject PackageInfo, can be fetched directly

  SettingsBloc({required SettingsRepository settingsRepository})
      : _settingsRepository = settingsRepository,
        super(const SettingsState()) {
    on<LoadSettings>(_onLoadSettings);
    on<UpdateTheme>(_onUpdateTheme);
    on<UpdateCurrency>(_onUpdateCurrency);
    on<UpdateAppLock>(_onUpdateAppLock);
  }

  Future<void> _onLoadSettings(
      LoadSettings event, Emitter<SettingsState> emit) async {
    // Emit loading for main settings and package info separately
    emit(state.copyWith(
      status: SettingsStatus.loading,
      packageInfoStatus: PackageInfoStatus.loading,
      clearMainError: true, // Clear previous errors on reload
      clearPackageInfoError: true,
    ));

    // Fetch Package Info Concurrently
    PackageInfo? packageInfo;
    String? packageInfoLoadError;
    try {
      packageInfo = await PackageInfo.fromPlatform();
      emit(state.copyWith(
        packageInfoStatus: PackageInfoStatus.loaded,
        appVersion: '${packageInfo.version}+${packageInfo.buildNumber}',
      ));
    } catch (e) {
      packageInfoLoadError = 'Failed to load app version: $e';
      emit(state.copyWith(
        packageInfoStatus: PackageInfoStatus.error,
        packageInfoError: packageInfoLoadError,
      ));
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

      if (settingsLoadError != null) {
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: settingsLoadError!.trim(),
          themeMode: loadedTheme, // Keep potentially loaded values
          currencySymbol: loadedSymbol,
          isAppLockEnabled: loadedLock,
        ));
      } else {
        emit(state.copyWith(
          status: SettingsStatus.loaded,
          themeMode: loadedTheme,
          currencySymbol: loadedSymbol,
          isAppLockEnabled: loadedLock,
          errorMessage: null, // Clear previous errors
        ));
      }
    } catch (e, stackTrace) {
      // Catch unexpected errors during settings fetch
      print("Unexpected error loading main settings: $e\n$stackTrace");
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'An unexpected error occurred loading settings.',
      ));
    }
  }

  // --- _onUpdateTheme, _onUpdateCurrency, _onUpdateAppLock remain the same ---
  Future<void> _onUpdateTheme(
      UpdateTheme event, Emitter<SettingsState> emit) async {
    final result = await _settingsRepository.saveThemeMode(event.newMode);
    result.fold(
      (failure) => emit(state.copyWith(
        status:
            SettingsStatus.error, // Keep overall status as error if save fails
        errorMessage: failure.message,
        clearPackageInfoError: true, // Clear unrelated errors
      )),
      (_) => emit(state.copyWith(
        themeMode: event.newMode,
        status: SettingsStatus.loaded, // Set overall status back to loaded
        clearMainError: true, // Clear previous error on success
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
        clearPackageInfoError: true,
      )),
      (_) => emit(state.copyWith(
        currencySymbol: event.newSymbol,
        status: SettingsStatus.loaded,
        clearMainError: true,
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
        clearPackageInfoError: true,
      )),
      (_) => emit(state.copyWith(
        isAppLockEnabled: event.isEnabled,
        status: SettingsStatus.loaded,
        clearMainError: true,
        clearPackageInfoError: true,
      )),
    );
  }
  // --- End unchanged methods ---
}
