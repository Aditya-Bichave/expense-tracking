import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CategoryManagementState', () {
    test('supports value comparisons', () {
      expect(
        const CategoryManagementState(),
        equals(const CategoryManagementState()),
      );
      expect(
        const CategoryManagementState(status: CategoryManagementStatus.loading),
        equals(
          const CategoryManagementState(
            status: CategoryManagementStatus.loading,
          ),
        ),
      );
      expect(
        const CategoryManagementState(status: CategoryManagementStatus.loaded),
        isNot(
          equals(
            const CategoryManagementState(
              status: CategoryManagementStatus.error,
            ),
          ),
        ),
      );
    });

    test('getters return correct lists', () {
      const exp1 = Category(
        id: '1',
        name: 'PreExp',
        iconName: 'i',
        colorHex: '#0',
        type: CategoryType.expense,
        isCustom: false,
      );
      const exp2 = Category(
        id: '2',
        name: 'CustExp',
        iconName: 'i',
        colorHex: '#0',
        type: CategoryType.expense,
        isCustom: true,
      );
      const inc1 = Category(
        id: '3',
        name: 'PreInc',
        iconName: 'i',
        colorHex: '#0',
        type: CategoryType.income,
        isCustom: false,
      );
      const inc2 = Category(
        id: '4',
        name: 'CustInc',
        iconName: 'i',
        colorHex: '#0',
        type: CategoryType.income,
        isCustom: true,
      );

      const state = CategoryManagementState(
        predefinedExpenseCategories: [exp1],
        customExpenseCategories: [exp2],
        predefinedIncomeCategories: [inc1],
        customIncomeCategories: [inc2],
      );

      expect(state.allExpenseCategories, equals([exp1, exp2]));
      expect(state.allIncomeCategories, equals([inc1, inc2]));
    });

    test('copyWith works correctly', () {
      const state = CategoryManagementState(
        status: CategoryManagementStatus.loading,
        errorMessage: 'error',
      );

      expect(
        state.copyWith(status: CategoryManagementStatus.loaded),
        equals(
          const CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            errorMessage: 'error',
          ),
        ),
      );

      expect(
        state.copyWith(errorMessage: 'new error'),
        equals(
          const CategoryManagementState(
            status: CategoryManagementStatus.loading,
            errorMessage: 'new error',
          ),
        ),
      );

      expect(
        state.copyWith(clearError: true),
        equals(
          const CategoryManagementState(
            status: CategoryManagementStatus.loading,
            errorMessage: null,
          ),
        ),
      );
    });
  });
}
