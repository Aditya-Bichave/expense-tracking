import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/ui_kit/foundation/ui_enums.dart';

void main() {
  group('UiEnums', () {
    test('UiSize has correct values', () {
      expect(UiSize.values.length, 5);
      expect(UiSize.values, [
        UiSize.xs,
        UiSize.sm,
        UiSize.md,
        UiSize.lg,
        UiSize.xl,
      ]);
    });

    test('UiVariant has correct values', () {
      expect(UiVariant.values.length, 8);
      expect(UiVariant.values, [
        UiVariant.primary,
        UiVariant.secondary,
        UiVariant.ghost,
        UiVariant.destructive,
        UiVariant.destructiveSecondary,
        UiVariant.success,
        UiVariant.warning,
        UiVariant.info,
      ]);
    });

    test('UiState has correct values', () {
      expect(UiState.values.length, 8);
      expect(UiState.values, [
        UiState.enabled,
        UiState.disabled,
        UiState.loading,
        UiState.error,
        UiState.focused,
        UiState.hovered,
        UiState.pressed,
        UiState.selected,
      ]);
    });

    test('UiSpacing has correct values', () {
      expect(UiSpacing.values.length, 8);
      expect(UiSpacing.values, [
        UiSpacing.xxs,
        UiSpacing.xs,
        UiSpacing.sm,
        UiSpacing.md,
        UiSpacing.lg,
        UiSpacing.xl,
        UiSpacing.xxl,
        UiSpacing.xxxl,
      ]);
    });
  });
}
