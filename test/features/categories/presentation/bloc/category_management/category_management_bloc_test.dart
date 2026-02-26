// ignore_for_file: directives_ordering

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

// Mocks
class MockGetCategoriesUseCase extends Mock implements GetCategoriesUseCase {}

class MockAddCustomCategoryUseCase extends Mock
    implements AddCustomCategoryUseCase {}

class MockUpdateCustomCategoryUseCase extends Mock
    implements UpdateCustomCategoryUseCase {}

class MockDeleteCustomCategoryUseCase extends Mock
    implements DeleteCustomCategoryUseCase {}

// Fakes
class FakeNoParams extends Fake implements NoParams {}

class FakeAddCustomCategoryParams extends Fake
    implements AddCustomCategoryParams {}

class FakeUpdateCustomCategoryParams extends Fake
    implements UpdateCustomCategoryParams {}

class FakeDeleteCustomCategoryParams extends Fake
    implements DeleteCustomCategoryParams {}

void main() {
  late CategoryManagementBloc bloc;
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late MockAddCustomCategoryUseCase mockAddCustomCategoryUseCase;
  late MockUpdateCustomCategoryUseCase mockUpdateCustomCategoryUseCase;
  late MockDeleteCustomCategoryUseCase mockDeleteCustomCategoryUseCase;

  setUpAll(() {
    registerFallbackValue(FakeNoParams());
    registerFallbackValue(FakeAddCustomCategoryParams());
    registerFallbackValue(FakeUpdateCustomCategoryParams());
    registerFallbackValue(FakeDeleteCustomCategoryParams());
  });

  setUp(() {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    mockAddCustomCategoryUseCase = MockAddCustomCategoryUseCase();
    mockUpdateCustomCategoryUseCase = MockUpdateCustomCategoryUseCase();
    mockDeleteCustomCategoryUseCase = MockDeleteCustomCategoryUseCase();

    bloc = CategoryManagementBloc(
      getCategoriesUseCase: mockGetCategoriesUseCase,
      addCustomCategoryUseCase: mockAddCustomCategoryUseCase,
      updateCustomCategoryUseCase: mockUpdateCustomCategoryUseCase,
      deleteCustomCategoryUseCase: mockDeleteCustomCategoryUseCase,
    );
  });

  tearDown(() {
    bloc.close();
  });

  final tCategoryExpense = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: 'FFFFFF',
    isCustom: true,
    type: CategoryType.expense,
  );

  final tCategoryIncome = Category(
    id: '2',
    name: 'Salary',
    iconName: 'cash',
    colorHex: 'FFFFFF',
    isCustom: false,
    type: CategoryType.income,
  );

  group('CategoryManagementBloc', () {
    test('initial state is correct', () {
      expect(bloc.state.status, CategoryManagementStatus.initial);
    });

    blocTest<CategoryManagementBloc, CategoryManagementState>(
      'LoadCategories emits [loading, loaded] with sorted categories on success',
      setUp: () {
        when(
          () => mockGetCategoriesUseCase(any()),
        ).thenAnswer((_) async => Right([tCategoryExpense, tCategoryIncome]));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadCategories(forceReload: true)),
      expect: () => [
        isA<CategoryManagementState>().having(
          (s) => s.status,
          'status',
          CategoryManagementStatus.loading,
        ),
        isA<CategoryManagementState>()
            .having((s) => s.status, 'status', CategoryManagementStatus.loaded)
            .having(
              (s) => s.customExpenseCategories.length,
              'custom expense count',
              1,
            )
            .having(
              (s) => s.predefinedIncomeCategories.length,
              'predefined income count',
              1,
            ),
      ],
    );

    blocTest<CategoryManagementBloc, CategoryManagementState>(
      'AddCategory emits [loading] then triggers reload on success',
      setUp: () {
        when(
          () => mockAddCustomCategoryUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetCategoriesUseCase(any()),
        ).thenAnswer((_) async => const Right([]));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        const AddCategory(
          name: 'New Cat',
          iconName: 'icon',
          colorHex: '000000',
          type: CategoryType.expense,
        ),
      ),
      expect: () => [
        isA<CategoryManagementState>().having(
          (s) => s.status,
          'status',
          CategoryManagementStatus.loading,
        ),
        // The intermediate Loading from LoadCategories is filtered out by Equatable because state didn't change (Loading -> Loading)
        isA<CategoryManagementState>().having(
          (s) => s.status,
          'status',
          CategoryManagementStatus.loaded,
        ),
      ],
      verify: (_) {
        verify(() => mockAddCustomCategoryUseCase(any())).called(1);
        verify(() => mockGetCategoriesUseCase(any())).called(1);
      },
    );

    blocTest<CategoryManagementBloc, CategoryManagementState>(
      'UpdateCategory emits [loading] then reload on success',
      setUp: () {
        when(
          () => mockUpdateCustomCategoryUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetCategoriesUseCase(any()),
        ).thenAnswer((_) async => const Right([]));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(UpdateCategory(category: tCategoryExpense)),
      expect: () => [
        isA<CategoryManagementState>().having(
          (s) => s.status,
          'status',
          CategoryManagementStatus.loading,
        ),
        isA<CategoryManagementState>().having(
          (s) => s.status,
          'status',
          CategoryManagementStatus.loaded,
        ),
      ],
    );

    blocTest<CategoryManagementBloc, CategoryManagementState>(
      'DeleteCategory emits [loading] then reload on success',
      setUp: () {
        when(
          () => mockDeleteCustomCategoryUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGetCategoriesUseCase(any()),
        ).thenAnswer((_) async => const Right([]));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const DeleteCategory(categoryId: 'cat-id')),
      expect: () => [
        isA<CategoryManagementState>().having(
          (s) => s.status,
          'status',
          CategoryManagementStatus.loading,
        ),
        isA<CategoryManagementState>().having(
          (s) => s.status,
          'status',
          CategoryManagementStatus.loaded,
        ),
      ],
    );
  });
}
