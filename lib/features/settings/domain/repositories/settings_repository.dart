import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart'; // Make sure this path is correct
import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<Either<Failure, void>> saveThemeMode(ThemeMode mode);
  Future<Either<Failure, ThemeMode>> getThemeMode();
  Future<Either<Failure, void>> saveCurrencySymbol(String symbol);
  Future<Either<Failure, String?>> getCurrencySymbol(); // Nullable if not set
  Future<Either<Failure, void>> saveAppLockEnabled(bool enabled);
  Future<Either<Failure, bool>> getAppLockEnabled();
}
