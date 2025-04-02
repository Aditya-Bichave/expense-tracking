import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import SettingsState for defaults
import 'package:simple_logger/simple_logger.dart'; // Import Level for log.log

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    log.info("[SettingsRepo] Getting theme mode.");
    try {
      final themeMode = await localDataSource.getThemeMode();
      log.info("[SettingsRepo] Theme mode retrieved: ${themeMode.name}");
      return Right(themeMode);
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE, '[SettingsRepo] Error getting theme mode$e$s');
      return Left(
          SettingsFailure('Failed to load theme setting: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode) async {
    log.info("[SettingsRepo] Saving theme mode: ${mode.name}");
    try {
      await localDataSource.saveThemeMode(mode);
      log.info("[SettingsRepo] Theme mode saved successfully.");
      return const Right(null);
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE, '[SettingsRepo] Error saving theme mode$e$s');
      return Left(
          SettingsFailure('Failed to save theme setting: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> getThemeIdentifier() async {
    log.info("[SettingsRepo] Getting theme identifier.");
    try {
      final identifier = await localDataSource.getThemeIdentifier();
      log.info("[SettingsRepo] Theme identifier retrieved: $identifier");
      return Right(identifier);
    } catch (e, s) {
      // Use log.log
      log.log(
          Level.SEVERE, '[SettingsRepo] Error getting theme identifier$e$s');
      return Left(
          SettingsFailure('Failed to load theme identifier: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemeIdentifier(String identifier) async {
    log.info("[SettingsRepo] Saving theme identifier: $identifier");
    try {
      await localDataSource.saveThemeIdentifier(identifier);
      log.info("[SettingsRepo] Theme identifier saved successfully.");
      return const Right(null);
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE, '[SettingsRepo] Error saving theme identifier$e$s');
      return Left(
          SettingsFailure('Failed to save theme identifier: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String?>> getSelectedCountryCode() async {
    log.info("[SettingsRepo] Getting selected country code.");
    try {
      final code = await localDataSource.getSelectedCountryCode();
      log.info("[SettingsRepo] Selected country code retrieved: $code");
      return Right(code);
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE,
          '[SettingsRepo] Error getting selected country code$e$s');
      return Left(
          SettingsFailure('Failed to load country setting: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveSelectedCountryCode(
      String countryCode) async {
    log.info("[SettingsRepo] Saving selected country code: $countryCode");
    try {
      await localDataSource.saveSelectedCountryCode(countryCode);
      log.info("[SettingsRepo] Selected country code saved successfully.");
      return const Right(null);
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE,
          '[SettingsRepo] Error saving selected country code$e$s');
      return Left(
          SettingsFailure('Failed to save country setting: ${e.toString()}'));
    }
  }

  // --- Derived Currency Symbol ---
  @override
  Future<Either<Failure, String>> getCurrencySymbol() async {
    log.info("[SettingsRepo] Deriving currency symbol.");
    try {
      final codeEither = await getSelectedCountryCode();
      return codeEither.fold(
        (failure) {
          log.warning(
              "[SettingsRepo] Failed to get country code for currency derivation: ${failure.message}. Defaulting.");
          // CORRECTED: Access static const directly
          return Right(SettingsState.getCurrencyForCountry(
              SettingsState.defaultCountryCode));
        },
        (code) {
          // Use the static helper from SettingsState
          final symbol = SettingsState.getCurrencyForCountry(code);
          log.info(
              "[SettingsRepo] Derived currency symbol: $symbol for code: $code");
          return Right(symbol);
        },
      );
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE,
          '[SettingsRepo] Unexpected error deriving currency symbol$e$s');
      return Left(SettingsFailure(
          'Unexpected error deriving currency symbol: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> getAppLockEnabled() async {
    log.info("[SettingsRepo] Getting app lock status.");
    try {
      final isEnabled = await localDataSource.getAppLockEnabled();
      log.info("[SettingsRepo] App lock status retrieved: $isEnabled");
      return Right(isEnabled);
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE, '[SettingsRepo] Error getting app lock status$e$s');
      return Left(
          SettingsFailure('Failed to load app lock setting: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAppLockEnabled(bool enabled) async {
    log.info("[SettingsRepo] Saving app lock status: $enabled");
    try {
      await localDataSource.saveAppLockEnabled(enabled);
      log.info("[SettingsRepo] App lock status saved successfully.");
      return const Right(null);
    } catch (e, s) {
      // Use log.log
      log.log(Level.SEVERE, '[SettingsRepo] Error saving app lock status$e$s');
      return Left(
          SettingsFailure('Failed to save app lock setting: ${e.toString()}'));
    }
  }
}
