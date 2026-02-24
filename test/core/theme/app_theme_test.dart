import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppTheme', () {
    test('buildTheme returns AppThemeDataPair with light and dark themes', () {
      final themePair = AppTheme.buildTheme(UIMode.elemental, 'mock');

      expect(themePair, isA<AppThemeDataPair>());
      expect(themePair.light, isA<ThemeData>());
      expect(themePair.light.brightness, Brightness.light);
      expect(themePair.dark, isA<ThemeData>());
      expect(themePair.dark.brightness, Brightness.dark);
    });
  });
}
