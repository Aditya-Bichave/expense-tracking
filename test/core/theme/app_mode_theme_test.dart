import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ThemeAssetPaths', () {
    test('props work correctly', () {
      const paths = ThemeAssetPaths(
        mainBackgroundLight: 'light_bg',
        mainBackgroundDark: 'dark_bg',
      );
      expect(paths.mainBackgroundLight, 'light_bg');
      expect(paths.mainBackgroundDark, 'dark_bg');
    });
  });

  group('LayoutDensity', () {
    test('values are correct', () {
      expect(LayoutDensity.compact, isA<LayoutDensity>());
      expect(LayoutDensity.comfortable, isA<LayoutDensity>());
      expect(LayoutDensity.spacious, isA<LayoutDensity>());
    });
  });
}
