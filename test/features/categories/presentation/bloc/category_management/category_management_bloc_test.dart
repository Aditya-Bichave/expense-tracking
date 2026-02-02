
import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
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

class FakeAddCustomCategoryParams extends Fake
    implements AddCustomCategoryParams {}

class FakeUpdateCustomCategoryParams extends Fake
    implements UpdateCustomCategoryParams {}

class FakeDeleteCustomCategoryParams extends Fake
    implements DeleteCustomCategoryParams {}

void main() {
  late CategoryManagementBloc bloc;
  late MockGetCategoriesUseCase mockGetCategories;
  late MockAddCustomCategoryUseCase mockAddCategory;
  late MockUpdateCustomCategoryUseCase mockUpdateCategory;
  late MockDeleteCustomCategoryUseCase mockDeleteCategory;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeAddCustomCategoryParams());
    registerFallbackValue(FakeUpdateCustomCategoryParams());
    registerFallbackValue(FakeDeleteCustomCategoryParams());
  });

  setUp(() {
    mockGetCategories = MockGetCategoriesUseCase();
    mockAddCategory = MockAddCustomCategoryUseCase();
    mockUpdateCategory = MockUpdateCustomCategoryUseCase();
    mockDeleteCategory = MockDeleteCustomCategoryUseCase();

    bloc = CategoryManagementBloc(
      getCategoriesUseCase: mockGetCategories,
      addCustomCategoryUseCase: mockAddCategory,
      updateCustomCategoryUseCase: mockUpdateCategory,
      deleteCustomCategoryUseCase: mockDeleteCategory,
    );
  });

  tearDown(() {
    bloc.close();
  });

  const tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'fastfood',
    colorHex: '0xFF0000',
    type: CategoryType.expense,
    isCustom: false,
  );

  const tCustomCategory = Category(
    id: '2',
    name: 'My Custom',
    iconName: 'custom',
    colorHex: '0xFF0000',
    type: CategoryType.expense,
    isCustom: true,
  );

  final tAllCategories = [tCategory, tCustomCategory];

  group('CategoryManagementBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const CategoryManagementState());
    });

    group('LoadCategories', () {
      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits loaded state with sorted and grouped categories',
        build: () {
          when(() => mockGetCategories(any()))
              .thenAnswer((_) async => Right(tAllCategories));
          return bloc;
        },
        act: (bloc) => bloc.add(const LoadCategories()),
        expect: () => [
          const CategoryManagementState(
              status: CategoryManagementStatus.loading),
          CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: [tCustomCategory],
            predefinedExpenseCategories: [tCategory],
          ),
        ],
        verify: (_) {
          verify(() => mockGetCategories(const NoParams())).called(1);
        },
      );

      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'does not reload if already loaded and not forced',
        seed: () => const CategoryManagementState(
            status: CategoryManagementStatus.loaded),
        build: () => bloc,
        act: (bloc) => bloc.add(const LoadCategories()),
        expect: () => [],
      );
    });

    group('AddCategory', () {
      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits loading then triggers reload on success',
        build: () {
          when(() => mockAddCategory(any()))
              .thenAnswer((_) async => const Right(null));
           when(() => mockGetCategories(any()))
              .thenAnswer((_) async => Right(tAllCategories));
          return bloc;
        },
        act: (bloc) => bloc.add(const AddCategory(
            name: 'New', iconName: 'icon', colorHex: 'color', type: CategoryType.expense)),
        expect: () => [
          const CategoryManagementState(
              status: CategoryManagementStatus.loading),
          // It calls LoadCategories(forceReload: true) internally.
          // Since the state is already loading, it won't emit another loading state if it's identical.
          CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: [tCustomCategory],
            predefinedExpenseCategories: [tCategory],
          ),
        ],
      );

      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits error state on failure then reverts to loaded',
        build: () {
          when(() => mockAddCategory(any()))
              .thenAnswer((_) async => const Left(ValidationFailure('Invalid')));
          return bloc;
        },
        act: (bloc) => bloc.add(const AddCategory(
             name: 'New', iconName: 'icon', colorHex: 'color', type: CategoryType.expense)),
        expect: () => [
           const CategoryManagementState(
              status: CategoryManagementStatus.loading),
           const CategoryManagementState(
              status: CategoryManagementStatus.error, errorMessage: 'Invalid'),
           const CategoryManagementState(
              status: CategoryManagementStatus.loaded),
        ],
      );
    });

    group('DeleteCategory', () {
      // Need to seed state with categories for the fallback logic in _onDeleteCategory
      final loadedState = CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: [tCustomCategory],
            predefinedExpenseCategories: [tCategory],
      );

      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits loading then triggers reload on success',
        seed: () => loadedState,
        build: () {
          when(() => mockDeleteCategory(any()))
              .thenAnswer((_) async => const Right(null));
           when(() => mockGetCategories(any()))
              .thenAnswer((_) async => Right(tAllCategories));
          return bloc;
        },
        act: (bloc) => bloc.add(DeleteCategory(categoryId: tCustomCategory.id)),
        expect: () => [
           loadedState.copyWith(status: CategoryManagementStatus.loading, clearError: true),
           // Second loading state is suppressed as it is identical
           loadedState.copyWith(status: CategoryManagementStatus.loaded, clearError: true), // LoadCategories loaded
        ],
      );
    });
  });
}
