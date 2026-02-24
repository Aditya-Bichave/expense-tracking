import 'package:expense_tracker/core/theme/config/stitch_configs.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('StitchConfigs', () {
    test('StitchConfig properties', () {
      final config = StitchConfigs.getConfig(AppTheme.stitchPalette1);
      expect(config.paletteIdentifier, AppTheme.stitchPalette1);
      expect(config.lightColorScheme, isA<ColorScheme>());
      expect(config.layoutDensity, LayoutDensity.comfortable);
      // expect(config.cardStyle, CardStyle.outlined); // Assuming CardStyle has outlined, let's check
    });
  });
}
