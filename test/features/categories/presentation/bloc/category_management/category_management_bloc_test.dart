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
  late MockGetCategoriesUseCase mockGetCategoriesUseCase;
  late MockAddCustomCategoryUseCase mockAddCustomCategoryUseCase;
  late MockUpdateCustomCategoryUseCase mockUpdateCustomCategoryUseCase;
  late MockDeleteCustomCategoryUseCase mockDeleteCustomCategoryUseCase;
  late StreamController<DataChangedEvent> mockStreamController;

  final tCategory = Category(
    id: '1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: true,
  );

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(FakeAddCustomCategoryParams());
    registerFallbackValue(FakeUpdateCustomCategoryParams());
    registerFallbackValue(FakeDeleteCustomCategoryParams());
  });

  setUp(() {
    mockGetCategoriesUseCase = MockGetCategoriesUseCase();
    mockAddCustomCategoryUseCase = MockAddCustomCategoryUseCase();
    mockUpdateCustomCategoryUseCase = MockUpdateCustomCategoryUseCase();
    mockDeleteCustomCategoryUseCase = MockDeleteCustomCategoryUseCase();
    mockStreamController = StreamController<DataChangedEvent>();

    GetIt.instance.reset();
    GetIt.instance.registerSingleton<StreamController<DataChangedEvent>>(
      mockStreamController,
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
    GetIt.instance.reset();
    mockStreamController.close();
  });

  group('CategoryManagementBloc', () {
    test('initial state is correct', () {
      expect(bloc.state, const CategoryManagementState());
    });

    blocTest<CategoryManagementBloc, CategoryManagementState>(
      'emits [loading, loaded] on successful LoadCategories',
      setUp: () {
        when(
          () => mockGetCategoriesUseCase(any()),
        ).thenAnswer((_) async => Right([tCategory]));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadCategories()),
      expect: () => [
        const CategoryManagementState(status: CategoryManagementStatus.loading),
        CategoryManagementState(
          status: CategoryManagementStatus.loaded,
          customExpenseCategories: [tCategory],
        ),
      ],
    );
  });
}
