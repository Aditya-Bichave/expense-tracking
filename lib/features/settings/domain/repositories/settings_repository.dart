import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode

abstract class SettingsRepository {
  // Theme Mode
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode);
  Future<Either<Failure, ThemeMode>> getThemeMode();

  // Palette Identifier
  Future<Either<Failure, void>> savePaletteIdentifier(
    String identifier,
  ); // RENAMED
  Future<Either<Failure, String>> getPaletteIdentifier(); // RENAMED

  // UI Mode
  Future<Either<Failure, void>> saveUIMode(UIMode mode);
  Future<Either<Failure, UIMode>> getUIMode();

  // Country & Currency
  Future<Either<Failure, void>> saveSelectedCountryCode(String countryCode);
  Future<Either<Failure, String?>> getSelectedCountryCode();
  Future<Either<Failure, String>> getCurrencySymbol();

  // App Lock
  Future<Either<Failure, void>> saveAppLockEnabled(bool enabled);
  Future<Either<Failure, bool>> getAppLockEnabled();
}
