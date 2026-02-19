import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/constants/pref_keys.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late SettingsLocalDataSourceImpl dataSource;
  late MockSharedPreferences mockPrefs;
  late MockFlutterSecureStorage mockSecureStorage;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    mockSecureStorage = MockFlutterSecureStorage();
    dataSource = SettingsLocalDataSourceImpl(
      prefs: mockPrefs,
      secureStorage: mockSecureStorage,
    );
  });

  group('ThemeMode', () {
    test('getThemeMode returns light when stored value is light', () async {
      when(() => mockPrefs.getString(PrefKeys.themeMode)).thenReturn('light');
      final result = await dataSource.getThemeMode();
      expect(result, ThemeMode.light);
    });

    test('getThemeMode returns dark when stored value is dark', () async {
      when(() => mockPrefs.getString(PrefKeys.themeMode)).thenReturn('dark');
      final result = await dataSource.getThemeMode();
      expect(result, ThemeMode.dark);
    });

    test('getThemeMode returns default when stored value is null', () async {
      when(() => mockPrefs.getString(PrefKeys.themeMode)).thenReturn(null);
      final result = await dataSource.getThemeMode();
      expect(result, SettingsState.defaultThemeMode);
    });

    test('saveThemeMode saves correct string', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      await dataSource.saveThemeMode(ThemeMode.dark);
      verify(() => mockPrefs.setString(PrefKeys.themeMode, 'dark'));
    });
  });

  group('UIMode', () {
    test('getUIMode returns correct enum', () async {
      when(() => mockPrefs.getString(PrefKeys.uiMode)).thenReturn('quantum');
      final result = await dataSource.getUIMode();
      expect(result, UIMode.quantum);
    });

    test('saveUIMode saves correct string', () async {
      when(() => mockPrefs.setString(any(), any())).thenAnswer((_) async => true);
      await dataSource.saveUIMode(UIMode.aether);
      verify(() => mockPrefs.setString(PrefKeys.uiMode, 'aether'));
    });
  });

  group('App Lock', () {
    test('getAppLockEnabled returns true when stored value is "true"', () async {
      when(() => mockSecureStorage.read(key: PrefKeys.appLockEnabled))
          .thenAnswer((_) async => 'true');
      final result = await dataSource.getAppLockEnabled();
      expect(result, true);
    });

    test('getAppLockEnabled returns default when stored value is null', () async {
      when(() => mockSecureStorage.read(key: PrefKeys.appLockEnabled))
          .thenAnswer((_) async => null);
      final result = await dataSource.getAppLockEnabled();
      expect(result, AppConstants.defaultAppLockEnabled);
    });

    test('saveAppLockEnabled saves to secure storage', () async {
      when(() => mockSecureStorage.write(key: any(named: 'key'), value: any(named: 'value')))
          .thenAnswer((_) async {});

      await dataSource.saveAppLockEnabled(true);

      verify(() => mockSecureStorage.write(
        key: PrefKeys.appLockEnabled,
        value: 'true',
      )).called(1);
    });
  });
}
