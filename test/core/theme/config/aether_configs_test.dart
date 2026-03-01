import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/config/aether_configs.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

void main() {
  group('AetherConfigs', () {
    test('getConfig returns default config for invalid palette', () {
      final config = AetherConfigs.getConfig('unknown_palette');
      expect(config.paletteIdentifier, AppTheme.aetherPalette1);
    });

    test('getConfig returns specific config for valid palettes', () {
      expect(
        AetherConfigs.getConfig(AppTheme.aetherPalette1).paletteIdentifier,
        AppTheme.aetherPalette1,
      );
      expect(
        AetherConfigs.getConfig(AppTheme.aetherPalette2).paletteIdentifier,
        AppTheme.aetherPalette2,
      );
      expect(
        AetherConfigs.getConfig(AppTheme.aetherPalette3).paletteIdentifier,
        AppTheme.aetherPalette3,
      );
      expect(
        AetherConfigs.getConfig(AppTheme.aetherPalette4).paletteIdentifier,
        AppTheme.aetherPalette4,
      );
    });

    test('AetherConfig specific properties are accessible', () {
      final config =
          AetherConfigs.getConfig(AppTheme.aetherPalette1) as AetherConfig;
      expect(config.incomeGlowColorLight, isNotNull);
      expect(config.expenseGlowColorLight, isNotNull);
      expect(config.incomeGlowColorDark, isNotNull);
      expect(config.expenseGlowColorDark, isNotNull);
      expect(config.cardOuterPadding, isNotNull);
    });
  });
}
