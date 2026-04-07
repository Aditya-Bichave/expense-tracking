import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/assets/app_assets.dart';

void main() {
  group('AppAssets constants', () {
    test('check core assets', () {
      expect(AppAssets.elBgLight, equals('assets/elemental/backgrounds/bg_elemental_light.svg'));
      expect(AppAssets.qBgDark, equals('assets/quantum/backgrounds/bg_quantum_dark.svg'));
      expect(AppAssets.aeBgStarfield, equals('assets/aether/backgrounds/bg_palette1_starfield.svg'));
      expect(AppAssets.elComIconAdd, equals('assets/elemental/icons/common/ic_add.svg'));
    });
  });
}
