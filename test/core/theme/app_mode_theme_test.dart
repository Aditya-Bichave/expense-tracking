import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';

void main() {
  group('AppModeTheme spacing', () {
    const baseTheme = AppModeTheme(
      modeId: 'test',
      layoutDensity: LayoutDensity.comfortable,
      cardStyle: CardStyle.flat,
      assets: ThemeAssetPaths(),
      preferDataTableForLists: false,
      primaryAnimationDuration: Duration(milliseconds: 300),
      listEntranceAnimation: ListEntranceAnimation.none,
    );

    test('provides default spacing scale', () {
      expect(baseTheme.spacingSmall, 8.0);
      expect(baseTheme.spacingMedium, 16.0);
      expect(baseTheme.spacingLarge, 24.0);
    });

    test('copyWith overrides spacing values', () {
      final updated = baseTheme.copyWith(
        spacingSmall: 4.0,
        spacingMedium: 12.0,
        spacingLarge: 20.0,
      );
      expect(updated.spacingSmall, 4.0);
      expect(updated.spacingMedium, 12.0);
      expect(updated.spacingLarge, 20.0);
    });
  });
}
