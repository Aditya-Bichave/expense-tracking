import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/constants/pref_keys.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SettingsLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    dataSource = SettingsLocalDataSourceImpl(prefs: mockPrefs);
  });

  group('SettingsLocalDataSource', () {
    test('saveThemeMode should save to prefs', () async {
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);
      await dataSource.saveThemeMode(ThemeMode.dark);
      verify(() => mockPrefs.setString(PrefKeys.themeMode, 'dark')).called(1);
    });

    test('getThemeMode should return saved mode', () async {
      when(() => mockPrefs.getString(PrefKeys.themeMode)).thenReturn('light');
      final result = await dataSource.getThemeMode();
      expect(result, ThemeMode.light);
    });

    test('getThemeMode should return default when null', () async {
      when(() => mockPrefs.getString(PrefKeys.themeMode)).thenReturn(null);
      final result = await dataSource.getThemeMode();
      expect(result, SettingsState.defaultThemeMode);
    });

    test('saveUIMode should save to prefs', () async {
      when(
        () => mockPrefs.setString(any(), any()),
      ).thenAnswer((_) async => true);
      await dataSource.saveUIMode(UIMode.elemental);
      verify(() => mockPrefs.setString(PrefKeys.uiMode, 'elemental')).called(1);
    });

    test('getUIMode should return saved mode', () async {
      when(() => mockPrefs.getString(PrefKeys.uiMode)).thenReturn('quantum');
      final result = await dataSource.getUIMode();
      expect(result, UIMode.quantum);
    });

    test('getUIMode should return default when null', () async {
      when(() => mockPrefs.getString(PrefKeys.uiMode)).thenReturn(null);
      final result = await dataSource.getUIMode();
      expect(result, SettingsState.defaultUIMode);
    });

    test('saveAppLockEnabled should save to prefs', () async {
      when(() => mockPrefs.setBool(any(), any())).thenAnswer((_) async => true);
      await dataSource.saveAppLockEnabled(true);
      verify(() => mockPrefs.setBool(PrefKeys.appLockEnabled, true)).called(1);
    });

    test('getAppLockEnabled should return saved value', () async {
      when(() => mockPrefs.getBool(PrefKeys.appLockEnabled)).thenReturn(false);
      final result = await dataSource.getAppLockEnabled();
      expect(result, false);
    });

    test('getAppLockEnabled should return default (false) when null', () async {
      when(() => mockPrefs.getBool(PrefKeys.appLockEnabled)).thenReturn(null);
      final result = await dataSource.getAppLockEnabled();
      expect(result, false);
    });
  });
}
