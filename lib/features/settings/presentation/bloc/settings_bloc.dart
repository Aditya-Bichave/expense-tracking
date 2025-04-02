import 'dart:async';
import 'package:bloc/bloc.dart';
import 'package:dartz/dartz.dart'; // Import dartz for Either
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart'; // Ensure path is correct
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
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

    try {
      // Use Future.wait to load all settings concurrently
      final results = await Future.wait([
        _settingsRepository.getThemeMode(),
        _settingsRepository.getCurrencySymbol(),
        _settingsRepository.getAppLockEnabled(),
      ]);

      // *** Cast results explicitly before using .fold ***
      final themeResult = results[0] as Either<Failure, ThemeMode>;
      final currencyResult = results[1] as Either<Failure, String?>;
      final appLockResult = results[2] as Either<Failure, bool>;
      // *** End Casts ***

      // Initialize with current state defaults or loaded values
      ThemeMode loadedTheme = state.themeMode;
      // Use default from SettingsState as the final fallback
      String? loadedSymbol = SettingsState.defaultCurrencySymbol;
      bool loadedLock = state.isAppLockEnabled;
      String? combinedErrorMessage;

      themeResult.fold(
        (failure) => combinedErrorMessage =
            '${combinedErrorMessage ?? ''}${failure.message} ',
        (themeMode) => loadedTheme = themeMode, // Assign ThemeMode correctly
      );

      currencyResult.fold(
        (failure) => combinedErrorMessage =
            '${combinedErrorMessage ?? ''}${failure.message} ',
        (symbol) => loadedSymbol = symbol ??
            SettingsState
                .defaultCurrencySymbol, // Assign String? correctly, use default if null
      );

      appLockResult.fold(
        (failure) => combinedErrorMessage =
            '${combinedErrorMessage ?? ''}${failure.message} ',
        (isEnabled) => loadedLock = isEnabled, // Assign bool correctly
      );

      if (combinedErrorMessage != null) {
        emit(state.copyWith(
          status: SettingsStatus.error,
          errorMessage: combinedErrorMessage!.trim(),
          // Keep potentially partially loaded values or revert to defaults?
          // Here we keep loaded values where possible
          themeMode: loadedTheme,
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
      // Catch potential casting errors or other issues
      print("Unexpected error loading settings: $e\n$stackTrace");
      emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: 'An unexpected error occurred while loading settings.',
      ));
    }
  }

  // --- _onUpdateTheme, _onUpdateCurrency, _onUpdateAppLock remain the same ---
  Future<void> _onUpdateTheme(
      UpdateTheme event, Emitter<SettingsState> emit) async {
    final result = await _settingsRepository.saveThemeMode(event.newMode);
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (_) => emit(state.copyWith(
        themeMode: event.newMode,
        status: SettingsStatus.loaded,
        errorMessage: null,
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
  // --- End unchanged methods ---
}
