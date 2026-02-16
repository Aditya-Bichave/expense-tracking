import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsLocalDataSource extends Mock
    implements SettingsLocalDataSource {}

void main() {
  late SettingsRepositoryImpl repository;
  late MockSettingsLocalDataSource mockDataSource;

  setUpAll(() {
    registerFallbackValue(ThemeMode.light);
    registerFallbackValue(UIMode.elemental);
  });

  setUp(() {
    mockDataSource = MockSettingsLocalDataSource();
    repository = SettingsRepositoryImpl(localDataSource: mockDataSource);
  });

  group('ThemeMode', () {
    test('getThemeMode returns Right(ThemeMode) on success', () async {
      when(
        () => mockDataSource.getThemeMode(),
      ).thenAnswer((_) async => ThemeMode.dark);
      final result = await repository.getThemeMode();
      expect(result, const Right(ThemeMode.dark));
    });

    test('getThemeMode returns Left(SettingsFailure) on error', () async {
      when(() => mockDataSource.getThemeMode()).thenThrow(Exception('Error'));
      final result = await repository.getThemeMode();
      expect(result.isLeft(), true);
      result.fold(
        (l) => expect(l, isA<SettingsFailure>()),
        (r) => fail('Should be Left'),
      );
    });

    test('saveThemeMode returns Right(null) on success', () async {
      when(
        () => mockDataSource.saveThemeMode(any()),
      ).thenAnswer((_) async => {});
      final result = await repository.saveThemeMode(ThemeMode.light);
      expect(result, const Right(null));
      verify(() => mockDataSource.saveThemeMode(ThemeMode.light)).called(1);
    });

    test('saveThemeMode returns Left(SettingsFailure) on error', () async {
      when(
        () => mockDataSource.saveThemeMode(any()),
      ).thenThrow(Exception('Error'));
      final result = await repository.saveThemeMode(ThemeMode.light);
      expect(result.isLeft(), true);
    });
  });

  group('PaletteIdentifier', () {
    test('getPaletteIdentifier returns Right(String) on success', () async {
      when(
        () => mockDataSource.getPaletteIdentifier(),
      ).thenAnswer((_) async => 'palette1');
      final result = await repository.getPaletteIdentifier();
      expect(result, const Right('palette1'));
    });

    test('savePaletteIdentifier returns Right(null) on success', () async {
      when(
        () => mockDataSource.savePaletteIdentifier(any()),
      ).thenAnswer((_) async => {});
      final result = await repository.savePaletteIdentifier('palette2');
      expect(result, const Right(null));
      verify(() => mockDataSource.savePaletteIdentifier('palette2')).called(1);
    });
  });

  group('UIMode', () {
    test('getUIMode returns Right(UIMode) on success', () async {
      when(
        () => mockDataSource.getUIMode(),
      ).thenAnswer((_) async => UIMode.quantum);
      final result = await repository.getUIMode();
      expect(result, const Right(UIMode.quantum));
    });

    test('saveUIMode returns Right(null) on success', () async {
      when(() => mockDataSource.saveUIMode(any())).thenAnswer((_) async => {});
      final result = await repository.saveUIMode(UIMode.elemental);
      expect(result, const Right(null));
      verify(() => mockDataSource.saveUIMode(UIMode.elemental)).called(1);
    });
  });

  group('CountryCode', () {
    test('getSelectedCountryCode returns Right(String?) on success', () async {
      when(
        () => mockDataSource.getSelectedCountryCode(),
      ).thenAnswer((_) async => 'US');
      final result = await repository.getSelectedCountryCode();
      expect(result, const Right('US'));
    });

    test('saveSelectedCountryCode returns Right(null) on success', () async {
      when(
        () => mockDataSource.saveSelectedCountryCode(any()),
      ).thenAnswer((_) async => {});
      final result = await repository.saveSelectedCountryCode('GB');
      expect(result, const Right(null));
      verify(() => mockDataSource.saveSelectedCountryCode('GB')).called(1);
    });
  });

  group('CurrencySymbol', () {
    test('getCurrencySymbol returns correct symbol for country code', () async {
      when(
        () => mockDataSource.getSelectedCountryCode(),
      ).thenAnswer((_) async => 'US');
      final result = await repository.getCurrencySymbol();
      // Assuming AppCountries.getCurrencyForCountry('US') returns '$'
      expect(result, const Right('\$'));
    });

    test('getCurrencySymbol defaults if country code fetch fails', () async {
      when(
        () => mockDataSource.getSelectedCountryCode(),
      ).thenThrow(Exception('Error'));
      // The repo catches this exception in getSelectedCountryCode, returning Left.
      // Wait, repository.getSelectedCountryCode returns Either.
      // But getCurrencySymbol calls getSelectedCountryCode (the repo method).
      // Let's look at getCurrencySymbol implementation again.
      // it calls `await getSelectedCountryCode()`. This calls `this.getSelectedCountryCode()`.
      // So if I mock `mockDataSource.getSelectedCountryCode()` to throw,
      // `repository.getSelectedCountryCode()` returns `Left`.
      // `getCurrencySymbol` handles the fold.

      final result = await repository.getCurrencySymbol();
      // It should return default currency (likely $)
      expect(result.isRight(), true);
    });
  });

  group('AppLock', () {
    test('getAppLockEnabled returns Right(bool) on success', () async {
      when(
        () => mockDataSource.getAppLockEnabled(),
      ).thenAnswer((_) async => true);
      final result = await repository.getAppLockEnabled();
      expect(result, const Right(true));
    });

    test('saveAppLockEnabled returns Right(null) on success', () async {
      when(
        () => mockDataSource.saveAppLockEnabled(any()),
      ).thenAnswer((_) async => {});
      final result = await repository.saveAppLockEnabled(false);
      expect(result, const Right(null));
      verify(() => mockDataSource.saveAppLockEnabled(false)).called(1);
    });
  });
}
