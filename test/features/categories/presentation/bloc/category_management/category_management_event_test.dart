import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryManagementEvent', () {
    test('LoadCategories supports value comparisons', () {
      expect(
        const LoadCategories(forceReload: true),
        equals(const LoadCategories(forceReload: true)),
      );
      expect(
        const LoadCategories(),
        equals(const LoadCategories(forceReload: false)),
      );
      expect(
        const LoadCategories(forceReload: true),
        isNot(equals(const LoadCategories(forceReload: false))),
      );
    });

    test('AddCategory supports value comparisons', () {
      expect(
        const AddCategory(
          name: 'Food',
          iconName: 'food',
          colorHex: '#000000',
          type: CategoryType.expense,
        ),
        equals(
          const AddCategory(
            name: 'Food',
            iconName: 'food',
            colorHex: '#000000',
            type: CategoryType.expense,
          ),
        ),
      );
      expect(
        const AddCategory(
          name: 'Food',
          iconName: 'food',
          colorHex: '#000000',
          type: CategoryType.expense,
        ),
        isNot(
          equals(
            const AddCategory(
              name: 'Food',
              iconName: 'food',
              colorHex: '#000000',
              type: CategoryType.income,
            ),
          ),
        ),
      );
    });

    test('UpdateCategory supports value comparisons', () {
      const category1 = Category(
        id: '1',
        name: 'Food',
        iconName: 'food',
        colorHex: '#000000',
        type: CategoryType.expense,
        isCustom: true,
      );
      const category2 = Category(
        id: '1',
        name: 'Food',
        iconName: 'food',
        colorHex: '#000000',
        type: CategoryType.expense,
        isCustom: true,
      );
      const category3 = Category(
        id: '2',
        name: 'Food2',
        iconName: 'food2',
        colorHex: '#111111',
        type: CategoryType.expense,
        isCustom: true,
      );

      expect(
        const UpdateCategory(category: category1),
        equals(const UpdateCategory(category: category2)),
      );
      expect(
        const UpdateCategory(category: category1),
        isNot(equals(const UpdateCategory(category: category3))),
      );
    });

    test('DeleteCategory supports value comparisons', () {
      expect(
        const DeleteCategory(categoryId: '1'),
        equals(const DeleteCategory(categoryId: '1')),
      );
      expect(
        const DeleteCategory(categoryId: '1'),
        isNot(equals(const DeleteCategory(categoryId: '2'))),
      );
    });

    test('ClearCategoryMessages supports value comparisons', () {
      expect(
        const ClearCategoryMessages(),
        equals(const ClearCategoryMessages()),
      );
    });
  });
}
