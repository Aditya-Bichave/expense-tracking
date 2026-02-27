import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
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
    registerFallbackValue(NoParams());
    registerFallbackValue(const AddCustomCategoryParams(name: 'test', type: CategoryType.expense, iconName: 'icon', colorHex: '#000000'));
  });

  const tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: true,
  );

  blocTest<CategoryManagementBloc, CategoryManagementState>(
    'emits [loading, loaded] when LoadCategories succeeds',
    build: () {
      when(() => mockGetCategoriesUseCase(any())).thenAnswer((_) async => const Right([tCategory]));
      return CategoryManagementBloc(
        getCategoriesUseCase: mockGetCategoriesUseCase,
        addCustomCategoryUseCase: mockAddCustomCategoryUseCase,
        updateCustomCategoryUseCase: mockUpdateCustomCategoryUseCase,
        deleteCustomCategoryUseCase: mockDeleteCustomCategoryUseCase,
      );
    },
    act: (bloc) => bloc.add(const LoadCategories()),
    expect: () => [
      const CategoryManagementState(
        status: CategoryManagementStatus.loading,
        // clearError: true - Removed
      ),
      isA<CategoryManagementState>()
          .having((s) => s.status, 'status', CategoryManagementStatus.loaded)
          .having((s) => s.customExpenseCategories.length, 'customExp', 1),
    ],
  );

  blocTest<CategoryManagementBloc, CategoryManagementState>(
    'emits [loading, error, loaded] when AddCategory fails',
    build: () {
      when(
        () => mockAddCustomCategoryUseCase(any()),
      ).thenAnswer((_) async => const Left(ValidationFailure('Error')));
      return CategoryManagementBloc(
        getCategoriesUseCase: mockGetCategoriesUseCase,
        addCustomCategoryUseCase: mockAddCustomCategoryUseCase,
        updateCustomCategoryUseCase: mockUpdateCustomCategoryUseCase,
        deleteCustomCategoryUseCase: mockDeleteCustomCategoryUseCase,
      );
    },
    act: (bloc) => bloc.add(
      const AddCategory(name: 'New', type: CategoryType.expense, iconName: 'icon', colorHex: '#000000'),
    ),
    expect: () => [
      const CategoryManagementState(
        status: CategoryManagementStatus.loading,
        // clearError: true - Removed
      ),
      isA<CategoryManagementState>()
          .having((s) => s.status, 'status', CategoryManagementStatus.error)
          .having((s) => s.errorMessage, 'error', 'Error'),
      isA<CategoryManagementState>()
          .having((s) => s.status, 'status', CategoryManagementStatus.loaded),
    ],
  );
}
