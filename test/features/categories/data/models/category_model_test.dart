import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: true,
    parentCategoryId: 'parent1',
  );

  final tCategoryModel = CategoryModel(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FF0000',
    isCustom: true,
    parentCategoryId: 'parent1',
    typeIndex: CategoryType.expense.index,
  );

  group('CategoryModel', () {
    test('toEntity should return valid entity', () {
      final result = tCategoryModel.toEntity();
      expect(result, tCategory);
    });

    test('fromEntity should return valid model', () {
      final result = CategoryModel.fromEntity(tCategory);
      expect(result.id, tCategoryModel.id);
      expect(result.typeIndex, tCategoryModel.typeIndex);
    });
  });
}
