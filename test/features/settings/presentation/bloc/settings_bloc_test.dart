import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/toggle_app_lock.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockDemoModeService extends Mock implements DemoModeService {}

class MockToggleAppLockUseCase extends Mock implements ToggleAppLockUseCase {}

void main() {
  late SettingsBloc bloc;
  late MockSettingsRepository mockRepository;
  late MockDemoModeService mockDemoModeService;
  late MockToggleAppLockUseCase mockToggleAppLockUseCase;

  setUpAll(() {
    registerFallbackValue(ThemeMode.light);
    registerFallbackValue(UIMode.elemental);
  });

  setUp(() {
    mockRepository = MockSettingsRepository();
    mockDemoModeService = MockDemoModeService();
    mockToggleAppLockUseCase = MockToggleAppLockUseCase();

    // Default mock behaviors
    when(() => mockDemoModeService.isDemoActive).thenReturn(false);
  });

  blocTest<SettingsBloc, SettingsState>(
    'LoadSettings emits success state when all repos return Right',
    build: () {
      when(
        () => mockRepository.getThemeMode(),
      ).thenAnswer((_) async => const Right(ThemeMode.dark));
      when(
        () => mockRepository.getPaletteIdentifier(),
      ).thenAnswer((_) async => const Right('palette1'));
      when(
        () => mockRepository.getUIMode(),
      ).thenAnswer((_) async => const Right(UIMode.quantum));
      when(
        () => mockRepository.getSelectedCountryCode(),
      ).thenAnswer((_) async => const Right('US'));
      when(
        () => mockRepository.getAppLockEnabled(),
      ).thenAnswer((_) async => const Right(true));

      return SettingsBloc(
        settingsRepository: mockRepository,
        demoModeService: mockDemoModeService,
        toggleAppLockUseCase: mockToggleAppLockUseCase,
      );
    },
    act: (bloc) => bloc.add(const LoadSettings()),
    expect: () => [
      isA<SettingsState>().having(
        (s) => s.status,
        'status',
        SettingsStatus.loading,
      ),
      isA<SettingsState>()
          .having((s) => s.status, 'status', SettingsStatus.loaded)
          .having((s) => s.themeMode, 'themeMode', ThemeMode.dark)
          .having((s) => s.paletteIdentifier, 'paletteId', 'palette1')
          .having((s) => s.uiMode, 'uiMode', UIMode.quantum)
          .having((s) => s.selectedCountryCode, 'country', 'US')
          .having((s) => s.isAppLockEnabled, 'appLock', true),
    ],
  );

  blocTest<SettingsBloc, SettingsState>(
    'UpdateTheme emits new state and saves to repo',
    build: () => SettingsBloc(
      settingsRepository: mockRepository,
      demoModeService: mockDemoModeService,
      toggleAppLockUseCase: mockToggleAppLockUseCase,
    ),
    setUp: () {
      when(
        () => mockRepository.saveThemeMode(any()),
      ).thenAnswer((_) async => const Right(null));
    },
    act: (bloc) => bloc.add(const UpdateTheme(ThemeMode.light)),
    expect: () => [
      isA<SettingsState>().having(
        (s) => s.themeMode,
        'themeMode',
        ThemeMode.light,
      ),
    ],
    verify: (_) {
      verify(() => mockRepository.saveThemeMode(ThemeMode.light)).called(1);
    },
  );

  blocTest<SettingsBloc, SettingsState>(
    'UpdateUIMode emits new state and saves to repo',
    build: () => SettingsBloc(
      settingsRepository: mockRepository,
      demoModeService: mockDemoModeService,
      toggleAppLockUseCase: mockToggleAppLockUseCase,
    ),
    setUp: () {
      when(
        () => mockRepository.saveUIMode(any()),
      ).thenAnswer((_) async => const Right(null));
      when(
        () => mockRepository.savePaletteIdentifier(any()),
      ).thenAnswer((_) async => const Right(null));
    },
    act: (bloc) => bloc.add(const UpdateUIMode(UIMode.aether)),
    expect: () => [
      isA<SettingsState>()
          .having((s) => s.uiMode, 'uiMode', UIMode.aether)
          // It also updates paletteIdentifier to default for that mode
          .having((s) => s.paletteIdentifier, 'paletteId', isNotEmpty),
    ],
    verify: (_) {
      verify(() => mockRepository.saveUIMode(UIMode.aether)).called(1);
      verify(() => mockRepository.savePaletteIdentifier(any())).called(1);
    },
  );

  blocTest<SettingsBloc, SettingsState>(
    'DemoMode interactions',
    build: () => SettingsBloc(
      settingsRepository: mockRepository,
      demoModeService: mockDemoModeService,
      toggleAppLockUseCase: mockToggleAppLockUseCase,
    ),
    act: (bloc) {
      bloc.add(const EnterDemoMode());
      bloc.add(const ExitDemoMode());
    },
    verify: (_) {
      verify(() => mockDemoModeService.enterDemoMode()).called(1);
      verify(() => mockDemoModeService.exitDemoMode()).called(1);
    },
  );

  blocTest<SettingsBloc, SettingsState>(
    'UpdateAppLock emits loading then success',
    build: () => SettingsBloc(
      settingsRepository: mockRepository,
      demoModeService: mockDemoModeService,
      toggleAppLockUseCase: mockToggleAppLockUseCase,
    ),
    setUp: () {
      when(
        () => mockToggleAppLockUseCase(any()),
      ).thenAnswer((_) async => const Right(null));
    },
    act: (bloc) => bloc.add(const UpdateAppLock(true)),
    expect: () => [
      isA<SettingsState>().having(
        (s) => s.status,
        'status',
        SettingsStatus.loading,
      ),
      isA<SettingsState>()
          .having((s) => s.isAppLockEnabled, 'appLock', true)
          .having((s) => s.status, 'status', SettingsStatus.loaded),
    ],
    verify: (_) {
      verify(() => mockToggleAppLockUseCase(true)).called(1);
    },
  );
}
