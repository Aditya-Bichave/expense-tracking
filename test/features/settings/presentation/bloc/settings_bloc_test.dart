import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:local_auth/local_auth.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockDemoModeService extends Mock implements DemoModeService {}

class MockLocalAuthentication extends Mock implements LocalAuthentication {}

void main() {
  late MockSettingsRepository repository;
  late MockDemoModeService demoModeService;
  late MockLocalAuthentication localAuth;

  setUp(() {
    repository = MockSettingsRepository();
    demoModeService = MockDemoModeService();
    localAuth = MockLocalAuthentication();
    when(() => demoModeService.isDemoActive).thenReturn(false);
  });

  SettingsBloc buildBloc() => SettingsBloc(
        settingsRepository: repository,
        demoModeService: demoModeService,
        localAuth: localAuth,
      );

  group('UpdateAppLock', () {
    blocTest<SettingsBloc, SettingsState>(
      'emits error when device lacks authentication capabilities',
      build: () {
        when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => false);
        when(
          () => localAuth.isDeviceSupported(),
        ).thenAnswer((_) async => false);
        return buildBloc();
      },
      act: (bloc) => bloc.add(const UpdateAppLock(true)),
      expect: () => [
        const SettingsState(
          isInDemoMode: false,
          setupSkipped: false,
          status: SettingsStatus.loading,
        ),
        const SettingsState(
          isInDemoMode: false,
          setupSkipped: false,
          status: SettingsStatus.error,
          errorMessage:
              'Cannot enable App Lock. Please set up device screen lock or biometrics first.',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'saves setting when authentication is available',
      build: () {
        when(() => localAuth.canCheckBiometrics).thenAnswer((_) async => true);
        when(
          () => repository.saveAppLockEnabled(true),
        ).thenAnswer((_) async => Right<Failure, void>(null));
        return buildBloc();
      },
      act: (bloc) => bloc.add(const UpdateAppLock(true)),
      expect: () => [
        const SettingsState(
          isInDemoMode: false,
          setupSkipped: false,
          status: SettingsStatus.loading,
        ),
        const SettingsState(
          isInDemoMode: false,
          setupSkipped: false,
          isAppLockEnabled: true,
          status: SettingsStatus.loaded,
        ),
      ],
      verify: (_) {
        verify(() => repository.saveAppLockEnabled(true)).called(1);
      },
    );
  });
}
