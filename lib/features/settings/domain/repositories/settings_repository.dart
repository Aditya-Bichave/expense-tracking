import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:flutter/material.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode

abstract class SettingsRepository {
  // Theme Mode
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode);
  Future<Either<Failure, ThemeMode>> getThemeMode();

  // Theme Identifier
  Future<Either<Failure, void>> saveThemeIdentifier(String identifier);
  Future<Either<Failure, String>>
      getThemeIdentifier(); // Returns default if not found

  // --- ADDED: UI Mode ---
  Future<Either<Failure, void>> saveUIMode(UIMode mode);
  Future<Either<Failure, UIMode>> getUIMode();
  // --- END ADDED ---

  // Country & Currency
  Future<Either<Failure, void>> saveSelectedCountryCode(String countryCode);
  Future<Either<Failure, String?>>
      getSelectedCountryCode(); // Nullable if not set
  Future<Either<Failure, String>>
      getCurrencySymbol(); // Derived from country code

  // App Lock
  Future<Either<Failure, void>> saveAppLockEnabled(bool enabled);
  Future<Either<Failure, bool>> getAppLockEnabled();
}
