import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBudgetLocalDataSource extends Mock implements BudgetLocalDataSource {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class FakeBudgetModel extends Fake implements BudgetModel {}

void main() {
  late BudgetRepositoryImpl repository;
  late MockBudgetLocalDataSource mockLocalDataSource;
  late MockExpenseRepository mockExpenseRepository;

  setUpAll(() {
    registerFallbackValue(FakeBudgetModel());
  });

  setUp(() {
    mockLocalDataSource = MockBudgetLocalDataSource();
    mockExpenseRepository = MockExpenseRepository();
    repository = BudgetRepositoryImpl(
      localDataSource: mockLocalDataSource,
      expenseRepository: mockExpenseRepository,
    );
  });

  final tBudget = Budget(
    id: '1',
    name: 'Monthly Budget',
    targetAmount: 500.0,
    period: BudgetPeriodType.recurringMonthly,
    startDate: DateTime(2024, 1, 1),
    categoryIds: const ['cat1'],
    type: BudgetType.categorySpecific,
    createdAt: DateTime.now(),
  );

  final tBudgetModel = BudgetModel(
    id: '1',
    name: 'Monthly Budget',
    targetAmount: 500.0,
    periodTypeIndex: 0,
    startDate: DateTime(2024, 1, 1),
    categoryIds: ['cat1'],
    budgetTypeIndex: 1,
    createdAt: DateTime.now(),
  );

  group('getBudgets', () {
    test('should return list of budgets from data source', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getBudgets(),
      ).thenAnswer((_) async => [tBudgetModel]);

      // Act
      final result = await repository.getBudgets();

      // Assert
      expect(result.isRight(), isTrue);
      final budgets = result.getOrElse(() => []);
      expect(budgets.first.id, tBudget.id);
    });

    test('should return CacheFailure when data source fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getBudgets(),
      ).thenThrow(const CacheFailure('Hive Error'));

      // Act
      final result = await repository.getBudgets();

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (r) => fail('Should return failure'),
      );
    });
  });

  group('addBudget', () {
    test('should return added budget when successful', () async {
      // Arrange
      // Mock fetching existing budgets for overlap check
      when(() => mockLocalDataSource.getBudgets()).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveBudget(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.addBudget(tBudget);

      // Assert
      verify(() => mockLocalDataSource.saveBudget(any())).called(1);
      expect(result, Right(tBudget));
    });
  });

  group('deleteBudget', () {
    test('should delete budget', () async {
      // Arrange
      when(
        () => mockLocalDataSource.deleteBudget(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteBudget('1');

      // Assert
      verify(() => mockLocalDataSource.deleteBudget('1')).called(1);
      expect(result, const Right(null));
    });
  });

  group('updateBudget', () {
    test('should update budget', () async {
      // Arrange
      when(() => mockLocalDataSource.getBudgets()).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveBudget(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.updateBudget(tBudget);

      // Assert
      verify(() => mockLocalDataSource.saveBudget(any())).called(1);
      expect(result, Right(tBudget));
    });
  });
}
