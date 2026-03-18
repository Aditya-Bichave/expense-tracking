import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/tokens/app_colors.dart';

void main() {
  test('AppColors assigns values from scheme', () {
    final scheme = const ColorScheme.light();
    final colors = AppColors(scheme);
    expect(colors.primary, equals(scheme.primary));
    expect(colors.surface, equals(scheme.surface));
  });
}
