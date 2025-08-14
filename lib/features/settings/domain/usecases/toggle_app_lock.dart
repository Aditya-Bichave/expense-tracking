import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

class ToggleAppLockUseCase {
  final SettingsRepository repository;
  final LocalAuthentication localAuth;

  ToggleAppLockUseCase(this.repository, this.localAuth);

  Future<Either<Failure, void>> call(bool enable) async {
    try {
      if (enable) {
        final canCheck = await localAuth.canCheckBiometrics ||
            await localAuth.isDeviceSupported();
        if (!canCheck) {
          return Left(
            ValidationFailure(
              'Cannot enable App Lock. Biometrics or device lock not available.',
            ),
          );
        }
      }
      return await repository.saveAppLockEnabled(enable);
    } on PlatformException catch (e) {
      return Left(UnexpectedFailure(e.message ?? e.code));
    } catch (e) {
      return Left(UnexpectedFailure(e.toString()));
    }
  }
}
