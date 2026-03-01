import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/tokens/app_radii.dart';

void main() {
  group('AppRadii', () {
    test('default instance has correct values', () {
      const radii = AppRadii();

      expect(radii.xs, 4.0);
      expect(radii.sm, 8.0);
      expect(radii.md, 12.0);
      expect(radii.lg, 16.0);
      expect(radii.xl, 24.0);
      expect(radii.full, 999.0);
    });

    test('raw Radius accessors work', () {
      const radii = AppRadii();

      expect(radii.rXs, const Radius.circular(4.0));
      expect(radii.rSm, const Radius.circular(8.0));
      expect(radii.rMd, const Radius.circular(12.0));
      expect(radii.rLg, const Radius.circular(16.0));
      expect(radii.rXl, const Radius.circular(24.0));
    });

    test('BorderRadius accessors work', () {
      const radii = AppRadii();

      expect(radii.xsmall, BorderRadius.circular(4.0));
      expect(radii.small, BorderRadius.circular(8.0));
      expect(radii.medium, BorderRadius.circular(12.0));
      expect(radii.large, BorderRadius.circular(16.0));
      expect(radii.extraLarge, BorderRadius.circular(24.0));
      expect(radii.circular, BorderRadius.circular(999.0));
    });

    test('semantic Radii work', () {
      const radii = AppRadii();

      expect(radii.card, BorderRadius.circular(12.0));
      expect(
        radii.sheet,
        const BorderRadius.vertical(top: Radius.circular(16.0)),
      );
      expect(radii.button, BorderRadius.circular(12.0));
      expect(radii.chip, BorderRadius.circular(999.0));
    });

    test('standard instance is accessible', () {
      expect(AppRadii.standard.xs, 4.0);
    });
  });
}
