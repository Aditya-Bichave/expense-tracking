import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Category', () {
    test('supports value equality', () {
      final c1 = Category(
        id: '1',
        name: 'A',
        iconName: 'i',
        colorHex: 'c',
        type: CategoryType.expense,
        isCustom: false,
      );
      final c2 = Category(
        id: '1',
        name: 'A',
        iconName: 'i',
        colorHex: 'c',
        type: CategoryType.expense,
        isCustom: false,
      );
      expect(c1, equals(c2));
    });

    test('cachedDisplayColor returns correct Color and caches it', () {
      const c1 = Category(
        id: '1',
        name: 'A',
        iconName: 'i',
        colorHex: '#FF0000',
        type: CategoryType.expense,
        isCustom: false,
      );

      final color1 = c1.cachedDisplayColor;
      expect(color1.value, 0xFFFF0000); // ARGB

      // Second call should return same result
      final color2 = c1.cachedDisplayColor;
      expect(color2, equals(color1));
    });
  });
}
