import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/tokens/app_typography.dart';

void main() {
  group('AppTypography', () {
    test('returns correct text styles mapped from TextTheme', () {
      const textTheme = TextTheme(
        displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.normal),
        headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.normal),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.normal),
        bodyLarge: TextStyle(fontSize: 16),
        bodyMedium: TextStyle(fontSize: 14),
        bodySmall: TextStyle(fontSize: 12),
        labelLarge: TextStyle(fontSize: 14),
        labelMedium: TextStyle(fontSize: 12),
        labelSmall: TextStyle(fontSize: 10),
      );

      final appTypography = AppTypography(textTheme);

      expect(appTypography.display.fontSize, 36);
      expect(appTypography.display.fontWeight, FontWeight.bold);

      expect(appTypography.title.fontSize, 24);
      expect(appTypography.title.fontWeight, FontWeight.w600);

      expect(appTypography.headline.fontSize, 22);
      expect(appTypography.headline.fontWeight, FontWeight.w600);

      expect(appTypography.body.fontSize, 14);

      expect(appTypography.bodyStrong.fontSize, 14);
      expect(appTypography.bodyStrong.fontWeight, FontWeight.w700);

      expect(appTypography.caption.fontSize, 12);

      expect(appTypography.overline.fontSize, 10);
      expect(appTypography.overline.fontWeight, FontWeight.w600);

      expect(appTypography.labelLarge.fontSize, 14);
      expect(appTypography.labelMedium.fontSize, 12);
      expect(appTypography.labelSmall.fontSize, 10);
      expect(appTypography.bodyLarge.fontSize, 16);
      expect(appTypography.bodyMedium.fontSize, 14);
      expect(appTypography.bodySmall.fontSize, 12);
    });
  });
}
