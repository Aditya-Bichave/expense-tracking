import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/config/quantum_configs.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';

void main() {
  group('QuantumConfigs', () {
    test('getConfig returns default config for invalid palette', () {
      final config = QuantumConfigs.getConfig('unknown_palette');
      expect(config.paletteIdentifier, AppTheme.quantumPalette1);
    });

    test('getConfig returns specific config for valid palettes', () {
      expect(
        QuantumConfigs.getConfig(AppTheme.quantumPalette1).paletteIdentifier,
        AppTheme.quantumPalette1,
      );
      expect(
        QuantumConfigs.getConfig(AppTheme.quantumPalette2).paletteIdentifier,
        AppTheme.quantumPalette2,
      );
      expect(
        QuantumConfigs.getConfig(AppTheme.quantumPalette3).paletteIdentifier,
        AppTheme.quantumPalette3,
      );
      expect(
        QuantumConfigs.getConfig(AppTheme.quantumPalette4).paletteIdentifier,
        AppTheme.quantumPalette4,
      );
    });

    test('QuantumConfig specific properties are accessible', () {
      final config =
          QuantumConfigs.getConfig(AppTheme.quantumPalette1) as QuantumConfig;
    });
  });
}
