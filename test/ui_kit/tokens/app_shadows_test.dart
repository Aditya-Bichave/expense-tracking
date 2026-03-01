import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/tokens/app_shadows.dart';

void main() {
  group('AppShadows', () {
    test('light mode generates correct shadows', () {
      const shadows = AppShadows(isDark: false);

      expect(shadows.sm.length, 1);
      expect(shadows.sm.first.color, Colors.black.withOpacity(0.05));

      expect(shadows.md.length, 2);
      expect(shadows.md.first.color, Colors.black.withOpacity(0.08));

      expect(shadows.lg.length, 2);
      expect(shadows.lg.first.color, Colors.black.withOpacity(0.1));

      expect(shadows.glow, shadows.sm);
    });

    test('dark mode generates correct shadows', () {
      const shadows = AppShadows(isDark: true);

      expect(shadows.sm.length, 1);
      expect(shadows.sm.first.color, Colors.black.withOpacity(0.3));

      expect(shadows.md.length, 1);
      expect(shadows.md.first.color, Colors.black.withOpacity(0.4));

      expect(shadows.lg.length, 1);
      expect(shadows.lg.first.color, Colors.black.withOpacity(0.5));

      expect(shadows.glow.length, 1);
      expect(
        shadows.glow.first.color,
        const Color(0xFF64B5F6).withOpacity(0.15),
      );
    });
  });
}
