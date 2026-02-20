import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}
class MockAddCustomCategoryUseCase extends Mock implements AddCustomCategoryUseCase {}
class MockUpdateCustomCategoryUseCase extends Mock implements UpdateCustomCategoryUseCase {}
class MockDeleteCustomCategoryUseCase extends Mock implements DeleteCustomCategoryUseCase {}

class FakeAddCustomCategoryParams extends Fake implements AddCustomCategoryParams {}
class FakeUpdateCustomCategoryParams extends Fake implements UpdateCustomCategoryParams {}
class FakeDeleteCustomCategoryParams extends Fake implements DeleteCustomCategoryParams {}
class FakeNoParams extends Fake implements NoParams {}

void main() {
  late CategoryManagementBloc bloc;
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late MockAddCustomCategoryUseCase mockAddCustomCategoryUseCase;
  late MockUpdateCustomCategoryUseCase mockUpdateCustomCategoryUseCase;
  late MockDeleteCustomCategoryUseCase mockDeleteCustomCategoryUseCase;

  setUpAll(() {
    registerFallbackValue(FakeAddCustomCategoryParams());
    registerFallbackValue(FakeUpdateCustomCategoryParams());
    registerFallbackValue(FakeDeleteCustomCategoryParams());
    registerFallbackValue(FakeNoParams());
  });

  setUp(() {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    mockAddCustomCategoryUseCase = MockAddCustomCategoryUseCase();
    mockUpdateCustomCategoryUseCase = MockUpdateCustomCategoryUseCase();
    mockDeleteCustomCategoryUseCase = MockDeleteCustomCategoryUseCase();

    GetIt.I.reset();
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    GetIt.I.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );

    bloc = CategoryManagementBloc(
      getCategoriesUseCase: mockGetCategoriesUseCase,
      addCustomCategoryUseCase: mockAddCustomCategoryUseCase,
      updateCustomCategoryUseCase: mockUpdateCustomCategoryUseCase,
      deleteCustomCategoryUseCase: mockDeleteCustomCategoryUseCase,
    );
  });

  tearDown(() {
    bloc.close();
    GetIt.I.reset();
  });

  final tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FFFFFF',
    type: CategoryType.expense,
    isCustom: true,
    parentCategoryId: null,
  );

  group('CategoryManagementBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, CategoryManagementStatus.initial);
    });

    group('LoadCategories', () {
      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits [loading, loaded] when GetCategories succeeds',
        build: () {
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => Right([tCategory]));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadCategories()),
        expect: () => [
          CategoryManagementState(status: CategoryManagementStatus.loading),
          CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: [tCategory],
            customIncomeCategories: [],
            predefinedExpenseCategories: [],
            predefinedIncomeCategories: [],
          ),
        ],
      );

      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits [loading, error] when GetCategories fails',
        build: () {
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => Left(CacheFailure('Error')));
          return bloc;
        },
        act: (bloc) => bloc.add(LoadCategories()),
        expect: () => [
          CategoryManagementState(status: CategoryManagementStatus.loading),
          CategoryManagementState(
            status: CategoryManagementStatus.error,
            errorMessage: 'Database Error: Error',
          ),
        ],
      );
    });

    group('AddCategory', () {
      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits [loading, loaded] (via LoadCategories) when AddCustomCategory succeeds',
        build: () {
          when(() => mockAddCustomCategoryUseCase(any()))
              .thenAnswer((_) async => Right(tCategory));
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => Right([tCategory]));
          return bloc;
        },
        act: (bloc) => bloc.add(AddCategory(
          name: 'Food',
          iconName: 'food',
          colorHex: '#FFFFFF',
          type: CategoryType.expense,
        )),
        expect: () => [
          CategoryManagementState(status: CategoryManagementStatus.loading),
          // Then LoadCategories triggers loading again (skipped if state is same, but here it changes from loading)
          // Actually, AddCategory calls LoadCategories.
          // State transition:
          // 1. Loading (from AddCategory)
          // 2. Loading (from LoadCategories) - emitted if distinct
          // 3. Loaded (from LoadCategories success)
          // CategoryManagementState(status: CategoryManagementStatus.loading),
          CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: [tCategory],
          ),
        ],
      );
    });

    group('DeleteCategory', () {
      final tCategoryToDelete = tCategory;

      blocTest<CategoryManagementBloc, CategoryManagementState>(
        'emits [loading, loaded] when DeleteCustomCategory succeeds',
        build: () {
          when(() => mockDeleteCustomCategoryUseCase(any()))
              .thenAnswer((_) async => const Right(null));
          when(() => mockGetCategoriesUseCase(any()))
              .thenAnswer((_) async => const Right([])); // Return empty after delete
          return bloc;
        },
        seed: () => CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: [tCategoryToDelete],
        ),
        act: (bloc) => bloc.add(DeleteCategory(categoryId: '1')),
        expect: () => [
          CategoryManagementState(
            status: CategoryManagementStatus.loading,
            customExpenseCategories: [tCategoryToDelete], // Keep old list while loading
          ),
          // Then LoadCategories triggers
          CategoryManagementState(
            status: CategoryManagementStatus.loaded,
            customExpenseCategories: [], // Empty now
          ),
        ],
      );
    });
  });
}
