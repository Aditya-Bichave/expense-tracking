import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toEntity defaults to expense when typeIndex is invalid', () {
    final model = CategoryModel(
      id: '1',
      name: 'Test',
      iconName: 'icon',
      colorHex: '#ffffff',
      isCustom: false,
      parentCategoryId: null,
      typeIndex: 99,
    );

    final entity = model.toEntity();
    expect(entity.type, CategoryType.expense);
  });
}
