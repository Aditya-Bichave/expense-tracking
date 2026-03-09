import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/domain/usecases/toggle_app_lock.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockToggleAppLockUseCase extends Mock implements ToggleAppLockUseCase {}

class MockDemoModeService extends Mock implements DemoModeService {}

void main() {
  group('SettingsBloc Comprehensive', () {
    late SettingsBloc bloc;
    late MockSettingsRepository mockSettingsRepository;
    late MockToggleAppLockUseCase mockToggleAppLockUseCase;
    late MockDemoModeService mockDemoModeService;

    setUpAll(() {
      registerFallbackValue(ThemeMode.system);
      registerFallbackValue(UIMode.elemental);
    });

    setUp(() {
      mockSettingsRepository = MockSettingsRepository();
      mockToggleAppLockUseCase = MockToggleAppLockUseCase();
      mockDemoModeService = MockDemoModeService();

      when(() => mockDemoModeService.isDemoActive).thenReturn(false);

      bloc = SettingsBloc(
        settingsRepository: mockSettingsRepository,
        toggleAppLockUseCase: mockToggleAppLockUseCase,
        demoModeService: mockDemoModeService,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    // --- LoadSettings ---
    blocTest<SettingsBloc, SettingsState>(
      'LoadSettings emits loaded state when all fetches succeed',
      build: () {
        when(
          () => mockSettingsRepository.getThemeMode(),
        ).thenAnswer((_) async => const Right(ThemeMode.dark));
        when(
          () => mockSettingsRepository.getPaletteIdentifier(),
        ).thenAnswer((_) async => const Right('palette1'));
        when(
          () => mockSettingsRepository.getUIMode(),
        ).thenAnswer((_) async => const Right(UIMode.quantum));
        when(
          () => mockSettingsRepository.getSelectedCountryCode(),
        ).thenAnswer((_) async => const Right('US'));
        when(
          () => mockSettingsRepository.getAppLockEnabled(),
        ).thenAnswer((_) async => const Right(true));
        return bloc;
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
            .having((s) => s.paletteIdentifier, 'palette', 'palette1')
            .having((s) => s.uiMode, 'uiMode', UIMode.quantum)
            .having((s) => s.selectedCountryCode, 'country', 'US')
            .having((s) => s.isAppLockEnabled, 'lock', true),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'LoadSettings emits error state when a fetch fails',
      build: () {
        when(
          () => mockSettingsRepository.getThemeMode(),
        ).thenAnswer((_) async => const Left(CacheFailure('Theme Error')));
        when(
          () => mockSettingsRepository.getPaletteIdentifier(),
        ).thenAnswer((_) async => const Left(CacheFailure('Palette Error')));
        when(
          () => mockSettingsRepository.getUIMode(),
        ).thenAnswer((_) async => const Right(UIMode.quantum));
        when(
          () => mockSettingsRepository.getSelectedCountryCode(),
        ).thenAnswer((_) async => const Right('US'));
        when(
          () => mockSettingsRepository.getAppLockEnabled(),
        ).thenAnswer((_) async => const Right(true));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((s) => s.status, 'status', SettingsStatus.error)
            .having(
              (s) => s.errorMessage,
              'error',
              'Theme Error\nPalette Error',
            ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'LoadSettings catches unexpected exception',
      build: () {
        when(
          () => mockSettingsRepository.getThemeMode(),
        ).thenThrow(Exception('Unexpected'));
        return bloc;
      },
      act: (bloc) => bloc.add(const LoadSettings()),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>().having(
          (s) => s.status,
          'status',
          SettingsStatus.error,
        ),
      ],
    );

    // --- UpdateTheme ---
    blocTest<SettingsBloc, SettingsState>(
      'UpdateTheme ignores event in demo mode',
      build: () {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateTheme(ThemeMode.dark)),
      expect: () => [],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateTheme updates theme mode when not in demo mode',
      build: () {
        when(
          () => mockSettingsRepository.saveThemeMode(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateTheme(ThemeMode.dark)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.themeMode,
          'themeMode',
          ThemeMode.dark,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateTheme handles failure',
      build: () {
        when(
          () => mockSettingsRepository.saveThemeMode(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Theme Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateTheme(ThemeMode.dark)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Theme Error',
        ),
      ],
    );

    // --- UpdatePaletteIdentifier ---
    blocTest<SettingsBloc, SettingsState>(
      'UpdatePaletteIdentifier ignores event in demo mode',
      build: () {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdatePaletteIdentifier('palette1')),
      expect: () => [],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdatePaletteIdentifier updates palette',
      build: () {
        when(
          () => mockSettingsRepository.savePaletteIdentifier(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdatePaletteIdentifier('palette1')),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.paletteIdentifier,
          'paletteIdentifier',
          'palette1',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdatePaletteIdentifier handles failure',
      build: () {
        when(
          () => mockSettingsRepository.savePaletteIdentifier(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Palette Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdatePaletteIdentifier('palette1')),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Palette Error',
        ),
      ],
    );

    // --- UpdateUIMode ---
    blocTest<SettingsBloc, SettingsState>(
      'UpdateUIMode ignores event in demo mode',
      build: () {
        when(() => mockDemoModeService.isDemoActive).thenReturn(true);
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateUIMode(UIMode.elemental)),
      expect: () => [],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateUIMode handles failure',
      build: () {
        when(
          () => mockSettingsRepository.saveUIMode(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('UI Mode Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateUIMode(UIMode.elemental)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'UI Mode Error',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateUIMode updates to elemental',
      build: () {
        when(
          () => mockSettingsRepository.saveUIMode(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSettingsRepository.savePaletteIdentifier(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateUIMode(UIMode.elemental)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.uiMode,
          'uiMode',
          UIMode.elemental,
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateUIMode updates to quantum',
      build: () {
        when(
          () => mockSettingsRepository.saveUIMode(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSettingsRepository.savePaletteIdentifier(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateUIMode(UIMode.quantum)),
      expect: () => [
        isA<SettingsState>().having((s) => s.uiMode, 'uiMode', UIMode.quantum),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateUIMode updates to aether',
      build: () {
        when(
          () => mockSettingsRepository.saveUIMode(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSettingsRepository.savePaletteIdentifier(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateUIMode(UIMode.aether)),
      expect: () => [
        isA<SettingsState>().having((s) => s.uiMode, 'uiMode', UIMode.aether),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateUIMode updates to stitch',
      build: () {
        when(
          () => mockSettingsRepository.saveUIMode(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSettingsRepository.savePaletteIdentifier(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateUIMode(UIMode.stitch)),
      expect: () => [
        isA<SettingsState>().having((s) => s.uiMode, 'uiMode', UIMode.stitch),
      ],
    );

    // --- UpdateCountry ---
    blocTest<SettingsBloc, SettingsState>(
      'UpdateCountry updates country',
      build: () {
        when(
          () => mockSettingsRepository.saveSelectedCountryCode(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateCountry('IN')),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.selectedCountryCode,
          'countryCode',
          'IN',
        ),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateCountry handles failure',
      build: () {
        when(
          () => mockSettingsRepository.saveSelectedCountryCode(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Country Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateCountry('IN')),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.errorMessage,
          'errorMessage',
          'Country Error',
        ),
      ],
    );

    // --- UpdateAppLock ---
    blocTest<SettingsBloc, SettingsState>(
      'UpdateAppLock updates lock',
      build: () {
        when(
          () => mockToggleAppLockUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateAppLock(true)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((s) => s.isAppLockEnabled, 'lock', true)
            .having((s) => s.status, 'status', SettingsStatus.loaded),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'UpdateAppLock handles failure',
      build: () {
        when(
          () => mockToggleAppLockUseCase(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Lock Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateAppLock(true)),
      expect: () => [
        isA<SettingsState>().having(
          (s) => s.status,
          'status',
          SettingsStatus.loading,
        ),
        isA<SettingsState>()
            .having((s) => s.errorMessage, 'errorMessage', 'Lock Error')
            .having((s) => s.status, 'status', SettingsStatus.error),
      ],
    );

    // --- Demo Mode ---
    blocTest<SettingsBloc, SettingsState>(
      'EnterDemoMode enters demo mode',
      build: () => bloc,
      act: (bloc) => bloc.add(const EnterDemoMode()),
      expect: () => [
        isA<SettingsState>().having((s) => s.isInDemoMode, 'demo', true),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'ExitDemoMode exits demo mode',
      build: () => bloc,
      act: (bloc) => bloc.add(const ExitDemoMode()),
      expect: () => [
        isA<SettingsState>().having((s) => s.isInDemoMode, 'demo', false),
      ],
    );

    // --- Misc ---
    blocTest<SettingsBloc, SettingsState>(
      'ClearSettingsMessage clears error',
      build: () => bloc,
      act: (bloc) => bloc.add(const ClearSettingsMessage()),
      expect: () => [
        isA<SettingsState>().having((s) => s.errorMessage, 'error', null),
      ],
    );

    blocTest<SettingsBloc, SettingsState>(
      'SkipSetup skips setup',
      build: () => bloc,
      act: (bloc) => bloc.add(const SkipSetup()),
      expect: () => [
        isA<SettingsState>().having((s) => s.setupSkipped, 'skip', true),
      ],
    );
  });

  group('SettingsState copyWith edge cases', () {
    test(
      'clears packageInfoError properly when clearAllMessages is true and new error is provided',
      () {
        const state = SettingsState(packageInfoError: 'old error');
        final newState = state.copyWith(
          clearAllMessages: true,
          packageInfoError: () => 'new error',
        );
        expect(newState.packageInfoError, 'new error');
      },
    );

    test(
      'clears packageInfoError when clearAllMessages is true and no new error is provided',
      () {
        const state = SettingsState(packageInfoError: 'old error');
        final newState = state.copyWith(clearAllMessages: true);
        expect(newState.packageInfoError, null);
      },
    );
  });
}
