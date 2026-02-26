import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockAddCustomCategoryUseCase extends Mock
    implements AddCustomCategoryUseCase {}

class MockUpdateCustomCategoryUseCase extends Mock
    implements UpdateCustomCategoryUseCase {}

class MockDeleteCustomCategoryUseCase extends Mock
    implements DeleteCustomCategoryUseCase {}

void main() {
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late MockAddCustomCategoryUseCase mockAddCustomCategoryUseCase;
  late MockUpdateCustomCategoryUseCase mockUpdateCustomCategoryUseCase;
  late MockDeleteCustomCategoryUseCase mockDeleteCustomCategoryUseCase;

  setUp(() {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    mockAddCustomCategoryUseCase = MockAddCustomCategoryUseCase();
    mockUpdateCustomCategoryUseCase = MockUpdateCustomCategoryUseCase();
    mockDeleteCustomCategoryUseCase = MockDeleteCustomCategoryUseCase();

    registerFallbackValue(
      const DeleteCustomCategoryParams(
        categoryId: 'id',
        fallbackExpenseCategoryId: 'fb',
      ),
    );
    registerFallbackValue(const NoParams());
  });

  group('CategoryManagementBloc', () {
    final tIncomeCategory = Category(
      id: 'inc1',
      name: 'Salary',
      iconName: 'money',
      colorHex: '#00FF00',
      type: CategoryType.income,
      isCustom: false,
    );

    blocTest<CategoryManagementBloc, CategoryManagementState>(
      'DeleteCategory uses correct fallback IDs for expense and income',
      build: () {
        when(
          () => mockDeleteCustomCategoryUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetCategoriesUseCase(any()),
        ).thenAnswer((_) async => Right([])); // For subsequent load

        return CategoryManagementBloc(
          getCategoriesUseCase: mockGetCategoriesUseCase,
          addCustomCategoryUseCase: mockAddCustomCategoryUseCase,
          updateCustomCategoryUseCase: mockUpdateCustomCategoryUseCase,
          deleteCustomCategoryUseCase: mockDeleteCustomCategoryUseCase,
        );
      },
      seed: () => CategoryManagementState(
        status: CategoryManagementStatus.loaded,
        predefinedIncomeCategories: [
          tIncomeCategory,
        ], // Seed with one income category
      ),
      act: (bloc) =>
          bloc.add(const DeleteCategory(categoryId: 'cat_to_delete')),
      verify: (_) {
        verify(
          () => mockDeleteCustomCategoryUseCase(
            DeleteCustomCategoryParams(
              categoryId: 'cat_to_delete',
              fallbackExpenseCategoryId: 'uncategorized', // Default hardcoded
              fallbackIncomeCategoryId: 'inc1', // Derived from state
            ),
          ),
        ).called(1);
      },
    );
  });
}
