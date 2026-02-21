import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

void main() {
  group('SettingsState', () {
    test('has correct default values', () {
      const state = SettingsState();
      expect(state.status, SettingsStatus.loading);
      expect(state.isInDemoMode, false);
      expect(state.setupSkipped, false);
    });

    test('supports equality with same values', () {
      expect(const SettingsState(), equals(const SettingsState()));
    });

    test('supports inequality with different values', () {
      expect(
        const SettingsState(status: SettingsStatus.loading),
        isNot(equals(const SettingsState(status: SettingsStatus.loaded))),
      );
    });

    test('has all expected status values', () {
      expect(SettingsStatus.values.length, 3);
      expect(SettingsStatus.values, contains(SettingsStatus.loading));
      expect(SettingsStatus.values, contains(SettingsStatus.loaded));
      expect(SettingsStatus.values, contains(SettingsStatus.error));
    });

    test('has all expected package info status values', () {
      expect(PackageInfoStatus.values.length, 3);
      expect(PackageInfoStatus.values, contains(PackageInfoStatus.loading));
      expect(PackageInfoStatus.values, contains(PackageInfoStatus.loaded));
      expect(PackageInfoStatus.values, contains(PackageInfoStatus.error));
    });

    test('default status values are correct', () {
      expect(SettingsState.defaultThemeMode, ThemeMode.system);
      expect(SettingsState.defaultCountryCode, 'US');
      expect(SettingsState.defaultAppLockEnabled, false);
    });
  });
}