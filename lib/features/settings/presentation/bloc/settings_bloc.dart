import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracking/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart'; // Required for ThemeMode

part 'settings_event.dart';
part 'settings_state.dart';

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository _settingsRepository;

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
    emit(state.copyWith(status: SettingsStatus.loading));

    // Use Future.wait to load all settings concurrently
    final results = await Future.wait([
      _settingsRepository.getThemeMode(),
      _settingsRepository.getCurrencySymbol(),
      _settingsRepository.getAppLockEnabled(),
    ]);

    // Process results - check for any failures
    bool hasError = false;
    String combinedErrorMessage = '';

    ThemeMode loadedTheme = state.themeMode; // Default if load fails
    String? loadedSymbol = state.currencySymbol; // Default if load fails
    bool loadedLock = state.isAppLockEnabled; // Default if load fails

    results[0].fold(
      // Theme Result
      (failure) {
        hasError = true;
        combinedErrorMessage += '${failure.message} ';
      },
      (themeMode) => loadedTheme = themeMode,
    );

    results[1].fold(
      // Currency Result
      (failure) {
        hasError = true;
        combinedErrorMessage += '${failure.message} ';
      },
      (symbol) =>
          loadedSymbol = symbol ?? state.currencySymbol, // Keep default if null
    );

    results[2].fold(
      // App Lock Result
      (failure) {
        hasError = true;
        combinedErrorMessage += '${failure.message} ';
      },
      (isEnabled) => loadedLock = isEnabled,
    );

    if (hasError) {
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: combinedErrorMessage.trim(),
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
  }

  Future<void> _onUpdateTheme(
      UpdateTheme event, Emitter<SettingsState> emit) async {
    // Optionally emit a loading state if saving takes time
    // emit(state.copyWith(status: SettingsStatus.loading));
    final result = await _settingsRepository.saveThemeMode(event.newMode);

    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        // On success, update state
        themeMode: event.newMode,
        status: SettingsStatus.loaded, // Reset status if loading was used
        errorMessage: null, // Clear error on success
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
      )),
      (_) => emit(state.copyWith(
        currencySymbol: event.newSymbol,
        status: SettingsStatus.loaded,
        errorMessage: null,
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
      )),
      (_) => emit(state.copyWith(
        isAppLockEnabled: event.isEnabled,
        status: SettingsStatus.loaded,
        errorMessage: null,
      )),
    );
  }
}
