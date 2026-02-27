import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

void main() {
  late BudgetRepositoryImpl repository;
  late MockBudgetLocalDataSource mockLocalDataSource;
  late MockExpenseRepository mockExpenseRepository;

  setUp(() {
    mockLocalDataSource = MockBudgetLocalDataSource();
    mockExpenseRepository = MockExpenseRepository();
    repository = BudgetRepositoryImpl(
      localDataSource: mockLocalDataSource,
      expenseRepository: mockExpenseRepository,
    );
    registerFallbackValue(
      BudgetModel(
        id: '1',
        name: 'test',
        targetAmount: 100,
        budgetTypeIndex: 0,
        periodTypeIndex: 0,
        startDate: DateTime.now(),
        createdAt: DateTime.now(),
      ),
    );
  });

  final tBudget = Budget(
    id: '1',
    name: 'Food',
    targetAmount: 500,
    type: BudgetType.categorySpecific,
    period: BudgetPeriodType.oneTime,
    categoryIds: ['cat1'],
    createdAt: DateTime.now(), // Fixed: DateTime.now() instead of null
  );

  group('addBudget', () {
    test('should call localDataSource.saveBudget and return Right(Budget)', () async {
      when(
        () => mockLocalDataSource.saveBudget(any()),
      ).thenAnswer((_) async {});

      // Stub getBudgets for overlap check
      when(() => mockLocalDataSource.getBudgets()).thenAnswer((_) async => []);

      final result = await repository.addBudget(tBudget);

      expect(result, isA<Right<Failure, Budget>>());
      verify(() => mockLocalDataSource.saveBudget(any())).called(1);
    });

    test('should return Left(CacheFailure) when save fails', () async {
      when(() => mockLocalDataSource.getBudgets()).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveBudget(any()),
      ).thenThrow(Exception('Error'));

      final result = await repository.addBudget(tBudget);

      expect(result, isA<Left<Failure, Budget>>());
    });
  });

  group('getBudgets', () {
    test('should return list of budgets from local source', () async {
      final tBudgetModel = BudgetModel.fromEntity(tBudget);
      when(
        () => mockLocalDataSource.getBudgets(),
      ).thenAnswer((_) async => [tBudgetModel]);

      final result = await repository.getBudgets();

      expect(result.isRight(), true);
      result.fold((l) => null, (r) => expect(r.first.id, tBudget.id));
    });
  });

  group('calculateAmountSpent', () {
    test('should calculate total correctly filtering by category', () async {
      final expenses = [
        ExpenseModel(
          id: '1',
          title: 'Lunch', // Fixed: Added title
          amount: 100,
          date: DateTime.now(),
          categoryId: 'cat1',
          accountId: 'acc1',
        ),
        ExpenseModel(
          id: '2',
          title: 'Dinner', // Fixed: Added title
          amount: 50,
          date: DateTime.now(),
          categoryId: 'cat2', // Should be ignored
          accountId: 'acc1',
        ),
      ];

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => Right(expenses));

      final result = await repository.calculateAmountSpent(
        budget: tBudget,
        periodStart: DateTime.now(),
        periodEnd: DateTime.now(),
      );

      expect(result, const Right(100.0));
    });
  });
}
