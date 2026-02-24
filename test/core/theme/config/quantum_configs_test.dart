import 'package:expense_tracker/core/theme/config/quantum_configs.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('QuantumConfigs', () {
    test('QuantumConfig properties', () {
      final config = QuantumConfigs.getConfig(AppTheme.quantumPalette1);
      expect(config.paletteIdentifier, AppTheme.quantumPalette1);
      expect(config.lightColorScheme, isA<ColorScheme>());
      expect(config.darkColorScheme, isA<ColorScheme>());
      expect(config.layoutDensity, LayoutDensity.compact);
      expect(config.cardStyle, CardStyle.flat);
    });

    test('getConfig returns default if identifier not found', () {
      final config = QuantumConfigs.getConfig('unknown');
      expect(config.paletteIdentifier, AppTheme.quantumPalette1);
    });
  });
}
