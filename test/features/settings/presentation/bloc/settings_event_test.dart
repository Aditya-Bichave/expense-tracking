import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

void main() {
  group('SettingsEvent', () {
    group('LoadSettings', () {
      test('supports equality', () {
        expect(const LoadSettings(), equals(const LoadSettings()));
      });
    });

    group('UpdateTheme', () {
      test('supports equality with same theme mode', () {
        expect(
          const UpdateTheme(ThemeMode.dark),
          equals(const UpdateTheme(ThemeMode.dark)),
        );
      });

      test('supports inequality with different theme mode', () {
        expect(
          const UpdateTheme(ThemeMode.dark),
          isNot(equals(const UpdateTheme(ThemeMode.light))),
        );
      });

      test('stores theme mode correctly', () {
        const event = UpdateTheme(ThemeMode.system);
        expect(event.newMode, ThemeMode.system);
      });
    });

    group('UpdatePaletteIdentifier', () {
      test('supports equality with same identifier', () {
        expect(
          const UpdatePaletteIdentifier('palette1'),
          equals(const UpdatePaletteIdentifier('palette1')),
        );
      });

      test('stores identifier correctly', () {
        const event = UpdatePaletteIdentifier('test-palette');
        expect(event.newIdentifier, 'test-palette');
      });
    });

    group('UpdateUIMode', () {
      test('supports equality with same UI mode', () {
        expect(
          const UpdateUIMode(UIMode.elemental),
          equals(const UpdateUIMode(UIMode.elemental)),
        );
      });

      test('stores UI mode correctly', () {
        const event = UpdateUIMode(UIMode.quantum);
        expect(event.newMode, UIMode.quantum);
      });
    });

    group('UpdateCountry', () {
      test('supports equality with same country code', () {
        expect(
          const UpdateCountry('US'),
          equals(const UpdateCountry('US')),
        );
      });

      test('stores country code correctly', () {
        const event = UpdateCountry('GB');
        expect(event.newCountryCode, 'GB');
      });
    });

    group('UpdateAppLock', () {
      test('supports equality with same value', () {
        expect(
          const UpdateAppLock(true),
          equals(const UpdateAppLock(true)),
        );
      });

      test('stores value correctly', () {
        const event = UpdateAppLock(false);
        expect(event.isEnabled, false);
      });
    });

    group('EnterDemoMode and ExitDemoMode', () {
      test('support equality', () {
        expect(const EnterDemoMode(), equals(const EnterDemoMode()));
        expect(const ExitDemoMode(), equals(const ExitDemoMode()));
      });
    });

    group('SkipSetup and ResetSkipSetupFlag', () {
      test('support equality', () {
        expect(const SkipSetup(), equals(const SkipSetup()));
        expect(const ResetSkipSetupFlag(), equals(const ResetSkipSetupFlag()));
      });
    });

    group('ClearSettingsMessage', () {
      test('supports equality', () {
        expect(
          const ClearSettingsMessage(),
          equals(const ClearSettingsMessage()),
        );
      });
    });
  });
}