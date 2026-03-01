import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/tokens/app_motion.dart';

void main() {
  group('AppMotion', () {
    test('default instance has correct values', () {
      const motion = AppMotion();

      expect(motion.fast, const Duration(milliseconds: 200));
      expect(motion.normal, const Duration(milliseconds: 350));
      expect(motion.slow, const Duration(milliseconds: 500));

      expect(motion.standard, Curves.easeInOut);
      expect(motion.emphasized, Curves.easeInOutCubicEmphasized);
      expect(motion.overshoot, isA<Cubic>());
    });

    test('standardInstance is accessible and correct', () {
      expect(
        AppMotion.standardInstance.fast,
        const Duration(milliseconds: 200),
      );
    });
  });
}
