import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart'; // Make sure this path is correct
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for PlatformException if needed

// Define a specific Failure if needed, otherwise use existing ones
class SettingsFailure extends Failure {
  const SettingsFailure(String message) : super(message);
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, ThemeMode>> getThemeMode() async {
    try {
      final themeMode = await localDataSource.getThemeMode();
      return Right(themeMode);
    } catch (e) {
      // TODO: Log error e properly
      print('Error getting theme mode: $e');
      return const Left(SettingsFailure('Failed to load theme setting.'));
    }
  }

  @override
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode) async {
    try {
      await localDataSource.saveThemeMode(mode);
      return const Right(
          null); // Use Right(unit) if using dartz's unit explicitly
    } catch (e) {
      // TODO: Log error e properly
      print('Error saving theme mode: $e');
      return const Left(SettingsFailure('Failed to save theme setting.'));
    }
  }

  @override
  Future<Either<Failure, String?>> getCurrencySymbol() async {
    try {
      final symbol = await localDataSource.getCurrencySymbol();
      // Return Right(symbol) which can be Right(null) if not set
      return Right(symbol);
    } catch (e) {
      // TODO: Log error e properly
      print('Error getting currency symbol: $e');
      return const Left(SettingsFailure('Failed to load currency setting.'));
    }
  }

  @override
  Future<Either<Failure, void>> saveCurrencySymbol(String symbol) async {
    try {
      await localDataSource.saveCurrencySymbol(symbol);
      return const Right(null);
    } catch (e) {
      // TODO: Log error e properly
      print('Error saving currency symbol: $e');
      return const Left(SettingsFailure('Failed to save currency setting.'));
    }
  }

  @override
  Future<Either<Failure, bool>> getAppLockEnabled() async {
    try {
      final isEnabled = await localDataSource.getAppLockEnabled();
      return Right(isEnabled);
    } catch (e) {
      // TODO: Log error e properly
      print('Error getting app lock enabled: $e');
      return const Left(SettingsFailure('Failed to load app lock setting.'));
    }
  }

  @override
  Future<Either<Failure, void>> saveAppLockEnabled(bool enabled) async {
    try {
      await localDataSource.saveAppLockEnabled(enabled);
      return const Right(null);
    } catch (e) {
      // TODO: Log error e properly
      print('Error saving app lock enabled: $e');
      return const Left(SettingsFailure('Failed to save app lock setting.'));
    }
  }
}
