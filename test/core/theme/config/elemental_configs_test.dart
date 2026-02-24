import 'package:expense_tracker/core/theme/config/elemental_configs.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ElementalConfigs', () {
    test('ElementalConfig properties', () {
      final config = ElementalConfigs.getConfig(AppTheme.elementalPalette1);
      expect(config.paletteIdentifier, AppTheme.elementalPalette1);
      expect(config.lightColorScheme, isA<ColorScheme>());
      expect(config.layoutDensity, LayoutDensity.comfortable);
      expect(config.cardStyle, CardStyle.elevated);
    });
  });
}
