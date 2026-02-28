import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uuid/uuid.dart';
import 'package:get_it/get_it.dart';

class MockAddBudgetUseCase extends Mock implements AddBudgetUseCase {}

class MockUpdateBudgetUseCase extends Mock implements UpdateBudgetUseCase {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockUuid extends Mock implements Uuid {}

void main() {
  late AddEditBudgetBloc bloc;
  late MockAddBudgetUseCase mockAddBudgetUseCase;
  late MockUpdateBudgetUseCase mockUpdateBudgetUseCase;
  late MockCategoryRepository mockCategoryRepository;
  late MockUuid mockUuid;

  final tCategory = Category(
    id: 'cat1',
    name: 'Food',
    iconName: 'food',
    colorHex: 'red',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tBudget = Budget(
    id: 'b1',
    name: 'Test Budget',
    targetAmount: 100.0,
    period: BudgetPeriodType.recurringMonthly,
    type: BudgetType.overall,
    createdAt: DateTime(2023, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(
      const AddBudgetParams(
        name: '',
        type: BudgetType.overall,
        targetAmount: 0,
        period: BudgetPeriodType.recurringMonthly,
      ),
    );
    registerFallbackValue(UpdateBudgetParams(budget: tBudget));
  });

  setUp(() {
    mockAddBudgetUseCase = MockAddBudgetUseCase();
    mockUpdateBudgetUseCase = MockUpdateBudgetUseCase();
    mockCategoryRepository = MockCategoryRepository();
    mockUuid = MockUuid();

    // Setup GetIt for Uuid if used in bloc
    final sl = GetIt.instance;
    if (sl.isRegistered<Uuid>()) sl.unregister<Uuid>();
    sl.registerSingleton<Uuid>(mockUuid);

    when(
      () => mockCategoryRepository.getSpecificCategories(
        type: any(named: 'type'),
        includeCustom: any(named: 'includeCustom'),
      ),
    ).thenAnswer((_) async => Right([tCategory]));

    bloc = AddEditBudgetBloc(
      addBudgetUseCase: mockAddBudgetUseCase,
      updateBudgetUseCase: mockUpdateBudgetUseCase,
      categoryRepository: mockCategoryRepository,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('AddEditBudgetBloc', () {
    test('initial state should be initial (ready) or loading', () {
      expect(
        bloc.state.status,
        anyOf(AddEditBudgetStatus.loading, AddEditBudgetStatus.initial),
      );
    });

    blocTest<AddEditBudgetBloc, AddEditBudgetState>(
      'should emit [loading, initial] with categories when InitializeBudgetForm is called',
      build: () => bloc,
      act: (bloc) => bloc.add(const InitializeBudgetForm()),
      expect: () => [
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.loading,
        ),
        predicate<AddEditBudgetState>(
          (s) =>
              s.status == AddEditBudgetStatus.initial &&
              s.availableCategories.contains(tCategory),
        ),
      ],
    );

    blocTest<AddEditBudgetBloc, AddEditBudgetState>(
      'should emit [loading, initial, loading, success] when SaveBudget (Add) is successful',
      build: () {
        when(() => mockUuid.v4()).thenReturn('new-id');
        when(
          () => mockAddBudgetUseCase(any()),
        ).thenAnswer((_) async => Right(tBudget));
        return AddEditBudgetBloc(
          addBudgetUseCase: mockAddBudgetUseCase,
          updateBudgetUseCase: mockUpdateBudgetUseCase,
          categoryRepository: mockCategoryRepository,
        );
      },
      act: (bloc) => bloc.add(
        const SaveBudget(
          name: 'New Budget',
          targetAmount: 200,
          type: BudgetType.overall,
          period: BudgetPeriodType.recurringMonthly,
        ),
      ),
      expect: () => [
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.loading,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.initial,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.loading,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.success,
        ),
      ],
    );

    blocTest<AddEditBudgetBloc, AddEditBudgetState>(
      'should emit [loading, initial, loading, success] when SaveBudget (Update) is successful',
      build: () {
        when(
          () => mockUpdateBudgetUseCase(any()),
        ).thenAnswer((_) async => Right(tBudget));
        return AddEditBudgetBloc(
          addBudgetUseCase: mockAddBudgetUseCase,
          updateBudgetUseCase: mockUpdateBudgetUseCase,
          categoryRepository: mockCategoryRepository,
          initialBudget: tBudget,
        );
      },
      act: (bloc) => bloc.add(
        SaveBudget(
          name: 'Updated Name',
          targetAmount: tBudget.targetAmount,
          type: tBudget.type,
          period: tBudget.period,
        ),
      ),
      expect: () => [
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.loading,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.initial,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.loading,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.success,
        ),
      ],
    );

    blocTest<AddEditBudgetBloc, AddEditBudgetState>(
      'should emit [loading, initial, loading, error] when SaveBudget fails',
      build: () {
        when(() => mockUuid.v4()).thenReturn('new-id');
        when(
          () => mockAddBudgetUseCase(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Save failed')));
        return AddEditBudgetBloc(
          addBudgetUseCase: mockAddBudgetUseCase,
          updateBudgetUseCase: mockUpdateBudgetUseCase,
          categoryRepository: mockCategoryRepository,
        );
      },
      act: (bloc) => bloc.add(
        const SaveBudget(
          name: 'Fail Budget',
          targetAmount: 100,
          type: BudgetType.overall,
          period: BudgetPeriodType.recurringMonthly,
        ),
      ),
      expect: () => [
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.loading,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.initial,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.loading,
        ),
        predicate<AddEditBudgetState>(
          (s) => s.status == AddEditBudgetStatus.error,
        ),
      ],
    );

    blocTest<AddEditBudgetBloc, AddEditBudgetState>(
      'should reset status when ClearBudgetFormMessage is called',
      build: () => bloc,
      seed: () => const AddEditBudgetState(
        status: AddEditBudgetStatus.error,
        errorMessage: 'Old Error',
      ),
      act: (bloc) => bloc.add(const ClearBudgetFormMessage()),
      expect: () => [
        predicate<AddEditBudgetState>(
          (s) =>
              s.status == AddEditBudgetStatus.initial && s.errorMessage == null,
        ),
      ],
    );
  });
}
