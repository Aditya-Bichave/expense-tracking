// lib/features/settings/data/repositories/settings_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode
import 'package:simple_logger/simple_logger.dart'; // Import Level for log.log

// *** Import the new AppCountries helper ***
import 'package:expense_tracker/core/data/countries.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final themeMode = await localDataSource.getThemeMode();
      return Right(themeMode);
    } catch (e, s) {
      log.log(Level.SEVERE, '[SettingsRepo] Error getting theme mode$e$s');
      return Left(
        SettingsFailure('Failed to load theme setting: ${e.toString()}'),
      );
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
      log.log(Level.SEVERE, '[SettingsRepo] Error saving theme mode$e$s');
      return Left(
        SettingsFailure('Failed to save theme setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getPaletteIdentifier() async {
    try {
      final identifier = await localDataSource.getPaletteIdentifier();
      return Right(identifier);
    } catch (e, s) {
      log.log(
        Level.SEVERE,
        '[SettingsRepo] Error getting palette identifier$e$s',
      );
      return Left(
        SettingsFailure('Failed to load palette identifier: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> savePaletteIdentifier(String identifier) async {
    log.info("[SettingsRepo] Saving palette identifier: $identifier");
    try {
      await localDataSource.savePaletteIdentifier(identifier);
      log.info("[SettingsRepo] Palette identifier saved successfully.");
      return const Right(null);
    } catch (e, s) {
      log.log(
        Level.SEVERE,
        '[SettingsRepo] Error saving palette identifier$e$s',
      );
      return Left(
        SettingsFailure('Failed to save palette identifier: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, UIMode>> getUIMode() async {
    try {
      final uiMode = await localDataSource.getUIMode();
      return Right(uiMode);
    } catch (e, s) {
      log.log(Level.SEVERE, '[SettingsRepo] Error getting UI mode$e$s');
      return Left(
        SettingsFailure('Failed to load UI mode setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveUIMode(UIMode mode) async {
    log.info("[SettingsRepo] Saving UI mode: ${mode.name}");
    try {
      await localDataSource.saveUIMode(mode);
      log.info("[SettingsRepo] UI mode saved successfully.");
      return const Right(null);
    } catch (e, s) {
      log.log(Level.SEVERE, '[SettingsRepo] Error saving UI mode$e$s');
      return Left(
        SettingsFailure('Failed to save UI mode setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String?>> getSelectedCountryCode() async {
    try {
      final code = await localDataSource.getSelectedCountryCode();
      return Right(code);
    } catch (e, s) {
      log.log(
        Level.SEVERE,
        '[SettingsRepo] Error getting selected country code$e$s',
      );
      return Left(
        SettingsFailure('Failed to load country setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveSelectedCountryCode(
    String countryCode,
  ) async {
    log.info("[SettingsRepo] Saving selected country code: $countryCode");
    try {
      await localDataSource.saveSelectedCountryCode(countryCode);
      log.info("[SettingsRepo] Selected country code saved successfully.");
      return const Right(null);
    } catch (e, s) {
      log.log(
        Level.SEVERE,
        '[SettingsRepo] Error saving selected country code$e$s',
      );
      return Left(
        SettingsFailure('Failed to save country setting: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getCurrencySymbol() async {
    try {
      final codeEither = await getSelectedCountryCode();
      return codeEither.fold(
        (failure) {
          log.warning(
            "[SettingsRepo] Failed to get country code for currency derivation: ${failure.message}. Defaulting.",
          );
          // *** FIXED: Call the method from AppCountries ***
          return Right(
            AppCountries.getCurrencyForCountry(AppCountries.defaultCountryCode),
          );
        },
        (code) {
          // *** FIXED: Call the method from AppCountries ***
          final symbol = AppCountries.getCurrencyForCountry(code);
          return Right(symbol);
        },
      );
    } catch (e, s) {
      log.log(
        Level.SEVERE,
        '[SettingsRepo] Unexpected error deriving currency symbol$e$s',
      );
      return Left(
        SettingsFailure(
          'Unexpected error deriving currency symbol: ${e.toString()}',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, bool>> getAppLockEnabled() async {
    try {
      final isEnabled = await localDataSource.getAppLockEnabled();
      return Right(isEnabled);
    } catch (e, s) {
      log.log(Level.SEVERE, '[SettingsRepo] Error getting app lock status$e$s');
      return Left(
        SettingsFailure('Failed to load app lock setting: ${e.toString()}'),
      );
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
      log.log(Level.SEVERE, '[SettingsRepo] Error saving app lock status$e$s');
      return Left(
        SettingsFailure('Failed to save app lock setting: ${e.toString()}'),
      );
    }
  }
}
