import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/tokens/app_spacing.dart';

void main() {
  group('AppSpacing', () {
    test('default instance has correct values', () {
      const spacing = AppSpacing();

      expect(spacing.xxs, 2.0);
      expect(spacing.xs, 4.0);
      expect(spacing.sm, 8.0);
      expect(spacing.md, 12.0);
      expect(spacing.lg, 16.0);
      expect(spacing.xl, 20.0);
      expect(spacing.xxl, 24.0);
      expect(spacing.xxxl, 32.0);
    });

    test('allInsets accessors work', () {
      const spacing = AppSpacing();

      expect(spacing.allXxs, const EdgeInsets.all(2.0));
      expect(spacing.allXs, const EdgeInsets.all(4.0));
      expect(spacing.allSm, const EdgeInsets.all(8.0));
      expect(spacing.allMd, const EdgeInsets.all(12.0));
      expect(spacing.allLg, const EdgeInsets.all(16.0));
      expect(spacing.allXl, const EdgeInsets.all(20.0));
      expect(spacing.allXxl, const EdgeInsets.all(24.0));
    });

    test('horizontal accessors work', () {
      const spacing = AppSpacing();

      expect(spacing.hXxs, const EdgeInsets.symmetric(horizontal: 2.0));
      expect(spacing.hXs, const EdgeInsets.symmetric(horizontal: 4.0));
      expect(spacing.hSm, const EdgeInsets.symmetric(horizontal: 8.0));
      expect(spacing.hMd, const EdgeInsets.symmetric(horizontal: 12.0));
      expect(spacing.hLg, const EdgeInsets.symmetric(horizontal: 16.0));
      expect(spacing.hXl, const EdgeInsets.symmetric(horizontal: 20.0));
      expect(spacing.hXxl, const EdgeInsets.symmetric(horizontal: 24.0));
    });

    test('vertical accessors work', () {
      const spacing = AppSpacing();

      expect(spacing.vXxs, const EdgeInsets.symmetric(vertical: 2.0));
      expect(spacing.vXs, const EdgeInsets.symmetric(vertical: 4.0));
      expect(spacing.vSm, const EdgeInsets.symmetric(vertical: 8.0));
      expect(spacing.vMd, const EdgeInsets.symmetric(vertical: 12.0));
      expect(spacing.vLg, const EdgeInsets.symmetric(vertical: 16.0));
      expect(spacing.vXl, const EdgeInsets.symmetric(vertical: 20.0));
      expect(spacing.vXxl, const EdgeInsets.symmetric(vertical: 24.0));
    });

    test('gap helpers work', () {
      const spacing = AppSpacing();

      expect(spacing.gapXxs.width, 2.0);
      expect(spacing.gapXxs.height, 2.0);

      expect(spacing.wXxs.width, 2.0);
      expect(spacing.wXxs.height, null);

      expect(spacing.hgapXxs.width, null);
      expect(spacing.hgapXxs.height, 2.0);
    });

    test('standard instance is accessible', () {
      expect(AppSpacing.standard.xs, 4.0);
    });
  });
}
