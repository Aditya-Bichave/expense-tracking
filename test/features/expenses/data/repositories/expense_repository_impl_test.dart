import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class FakeExpenseModel extends Fake implements ExpenseModel {}

void main() {
  late ExpenseRepositoryImpl repository;
  late MockExpenseLocalDataSource mockLocalDataSource;
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    registerFallbackValue(FakeExpenseModel());
  });

  setUp(() {
    mockLocalDataSource = MockExpenseLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();
    repository = ExpenseRepositoryImpl(
      localDataSource: mockLocalDataSource,
      categoryRepository: mockCategoryRepository,
    );
  });

  const tCategory = Category(
    id: 'cat1',
    name: 'Food',
    iconName: 'food',
    colorHex: '#000000',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tExpenseModel = ExpenseModel(
    id: '1',
    title: 'Lunch',
    amount: 15.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    categoryId: 'cat1',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 1.0,
  );

  final tExpense = Expense(
    id: '1',
    title: 'Lunch',
    amount: 15.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    category: tCategory,
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
  );

  group('addExpense', () {
    test(
      'should return hydrated Expense when data source call is successful',
      () async {
        // Arrange
        when(
          () => mockLocalDataSource.addExpense(any()),
        ).thenAnswer((_) async => tExpenseModel);
        when(
          () => mockCategoryRepository.getCategoryById(any()),
        ).thenAnswer((_) async => const Right(tCategory));

        // Act
        final result = await repository.addExpense(tExpense);

        // Assert
        verify(
          () => mockLocalDataSource.addExpense(any<ExpenseModel>()),
        ).called(1);
        verify(() => mockCategoryRepository.getCategoryById('cat1')).called(1);
        expect(result, Right(tExpense));
      },
    );

    test(
      'should return CacheFailure when data source throws CacheFailure',
      () async {
        // Arrange
        when(
          () => mockLocalDataSource.addExpense(any()),
        ).thenThrow(const CacheFailure('Hive Error'));

        // Act
        final result = await repository.addExpense(tExpense);

        // Assert
        expect(result, const Left(CacheFailure('Hive Error')));
      },
    );
  });

  group('deleteExpense', () {
    test('should return void when delete is successful', () async {
      // Arrange
      when(
        () => mockLocalDataSource.deleteExpense(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteExpense('1');

      // Assert
      verify(() => mockLocalDataSource.deleteExpense('1')).called(1);
      expect(result, const Right(null));
    });

    test('should return CacheFailure when delete fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.deleteExpense(any()),
      ).thenThrow(const CacheFailure('Delete Error'));

      // Act
      final result = await repository.deleteExpense('1');

      // Assert
      expect(result, const Left(CacheFailure('Delete Error')));
    });
  });

  group('getExpenses', () {
    test('should return list of ExpenseModels from data source', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [tExpenseModel]);

      // Act
      final result = await repository.getExpenses();

      // Assert
      verify(
        () => mockLocalDataSource.getExpenses(
          startDate: null,
          endDate: null,
          categoryId: null,
          accountId: null,
        ),
      ).called(1);
      // expect(result, Right([tExpenseModel])); // Fails due to list identity
      expect(result.isRight(), isTrue);
      result.fold((l) => fail('should be right'), (r) {
        expect(r, [tExpenseModel]);
      });
    });

    test('should return CacheFailure when getting expenses fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(const CacheFailure('Fetch Error'));

      // Act
      final result = await repository.getExpenses();

      // Assert
      expect(result, const Left(CacheFailure('Fetch Error')));
    });
  });

  group('updateExpense', () {
    test('should return updated Expense when successful', () async {
      // Arrange
      when(
        () => mockLocalDataSource.updateExpense(any()),
      ).thenAnswer((_) async => tExpenseModel);
      when(
        () => mockCategoryRepository.getCategoryById(any()),
      ).thenAnswer((_) async => const Right(tCategory));

      // Act
      final result = await repository.updateExpense(tExpense);

      // Assert
      verify(
        () => mockLocalDataSource.updateExpense(any<ExpenseModel>()),
      ).called(1);
      expect(result, Right(tExpense));
    });

    test('should return CacheFailure when update fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.updateExpense(any()),
      ).thenThrow(const CacheFailure('Update Error'));

      // Act
      final result = await repository.updateExpense(tExpense);

      // Assert
      expect(result, const Left(CacheFailure('Update Error')));
    });
  });

  group('updateExpenseCategorization', () {
    test('should update expense categorization successfully', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getExpenseById(any()),
      ).thenAnswer((_) async => tExpenseModel);
      when(
        () => mockLocalDataSource.updateExpense(any()),
      ).thenAnswer((_) async => tExpenseModel);

      // Act
      final result = await repository.updateExpenseCategorization(
        '1',
        'cat2',
        CategorizationStatus.needsReview,
        0.8,
      );

      // Assert
      verify(() => mockLocalDataSource.getExpenseById('1')).called(1);
      verify(
        () => mockLocalDataSource.updateExpense(any<ExpenseModel>()),
      ).called(1);
      expect(result, const Right(null));
    });

    test('should return CacheFailure if expense not found', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getExpenseById(any()),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.updateExpenseCategorization(
        '1',
        'cat2',
        CategorizationStatus.needsReview,
        0.8,
      );

      // Assert
      expect(result, const Left(CacheFailure("Expense not found.")));
      verifyNever(() => mockLocalDataSource.updateExpense(any()));
    });
  });
}
