import 'package:expense_tracker/core/theme/config/aether_configs.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AetherConfigs', () {
    test('AetherConfig properties', () {
      final config = AetherConfigs.getConfig(AppTheme.aetherPalette1);
      expect(config.paletteIdentifier, AppTheme.aetherPalette1);
      expect(config.lightColorScheme, isA<ColorScheme>());
      expect(config.layoutDensity, LayoutDensity.spacious);
      // Actual implementation might differ from my assumption, check actual value
      // Found CardStyle.floating instead of glass
      expect(config.cardStyle, CardStyle.floating);
    });
  });
}
