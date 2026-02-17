
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/toggle_app_lock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late ToggleAppLockUseCase useCase;
  late MockSettingsRepository mockRepository;
  late MockLocalAuthentication mockLocalAuth;

  setUp(() {
    mockRepository = MockSettingsRepository();
    mockLocalAuth = MockLocalAuthentication();
    useCase = ToggleAppLockUseCase(mockRepository, mockLocalAuth);
  });

  test(
      'should enable app lock when biometrics are available and save to repository',
      () async {
    // arrange
    when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => true);
    when(() => mockLocalAuth.isDeviceSupported()).thenAnswer((_) async => true);
    when(() => mockRepository.saveAppLockEnabled(any()))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(true);

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.saveAppLockEnabled(true));
  });

  test('should return validation failure when enabling but biometrics unavailable',
      () async {
    // arrange
    when(() => mockLocalAuth.canCheckBiometrics).thenAnswer((_) async => false);
    when(() => mockLocalAuth.isDeviceSupported())
        .thenAnswer((_) async => false);

    // act
    final result = await useCase(true);

    // assert
    expect(
      result,
      Left(
        ValidationFailure(
          'Cannot enable App Lock. Biometrics or device lock not available.',
        ),
      ),
    );
    verifyZeroInteractions(mockRepository);
  });

  test('should disable app lock without checking biometrics', () async {
    // arrange
    when(() => mockRepository.saveAppLockEnabled(any()))
        .thenAnswer((_) async => const Right(null));

    // act
    final result = await useCase(false);

    // assert
    expect(result, const Right(null));
    verify(() => mockRepository.saveAppLockEnabled(false));
    verifyZeroInteractions(mockLocalAuth);
  });
}
