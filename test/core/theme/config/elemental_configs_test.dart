import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/config/elemental_configs.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

void main() {
  group('ElementalConfigs', () {
    test('getConfig returns default config for invalid palette', () {
      final config = ElementalConfigs.getConfig('unknown_palette');
      expect(config.paletteIdentifier, AppTheme.elementalPalette1);
    });

    test('getConfig returns specific config for valid palettes', () {
      expect(
        ElementalConfigs.getConfig(
          AppTheme.elementalPalette1,
        ).paletteIdentifier,
        AppTheme.elementalPalette1,
      );
      expect(
        ElementalConfigs.getConfig(
          AppTheme.elementalPalette2,
        ).paletteIdentifier,
        AppTheme.elementalPalette2,
      );
      expect(
        ElementalConfigs.getConfig(
          AppTheme.elementalPalette3,
        ).paletteIdentifier,
        AppTheme.elementalPalette3,
      );
      expect(
        ElementalConfigs.getConfig(
          AppTheme.elementalPalette4,
        ).paletteIdentifier,
        AppTheme.elementalPalette4,
      );
    });

    test('ElementalConfig specific properties are accessible', () {
      final config =
          ElementalConfigs.getConfig(AppTheme.elementalPalette1)
              as ElementalConfig;
    });
  });
}
