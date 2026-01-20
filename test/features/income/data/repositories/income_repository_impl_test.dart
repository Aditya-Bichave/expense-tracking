
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockIncomeLocalDataSource extends Mock implements IncomeLocalDataSource {}
class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late IncomeRepositoryImpl repository;
  late MockIncomeLocalDataSource mockLocalDataSource;
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    registerFallbackValue(IncomeModel(
      id: '1',
      title: 'Test',
      amount: 100.0,
      date: DateTime.now(),
      accountId: 'acc1',
    ));
    registerFallbackValue(CategorizationStatus.categorized);
  });

  setUp(() {
    mockLocalDataSource = MockIncomeLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();

    // Use constructor injection
    repository = IncomeRepositoryImpl(
      localDataSource: mockLocalDataSource,
      categoryRepository: mockCategoryRepository,
    );
  });

  const tCategory = Category(
    id: 'cat1',
    name: 'Job',
    iconName: 'work',
    colorHex: '#000000',
    type: CategoryType.income,
    isCustom: false,
  );

  final tIncome = Income(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: DateTime(2023, 10, 1),
    accountId: 'acc1',
    notes: 'Monthly salary',
    category: tCategory,
  );

  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Salary',
    amount: 5000.0,
    date: DateTime(2023, 10, 1),
    accountId: 'acc1',
    notes: 'Monthly salary',
    categoryId: 'cat1',
  );

  group('addIncome', () {
    test('should return Income with category when add is successful', () async {
      // Arrange
      when(() => mockLocalDataSource.addIncome(any()))
          .thenAnswer((_) async => tIncomeModel);
      when(() => mockCategoryRepository.getCategoryById('cat1'))
          .thenAnswer((_) async => Right(tCategory));

      // Act
      final result = await repository.addIncome(tIncome);

      // Assert
      verify(() => mockLocalDataSource.addIncome(any())).called(1);
      verify(() => mockCategoryRepository.getCategoryById('cat1')).called(1);
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (income) {
          expect(income.id, tIncomeModel.id);
          expect(income.category, tCategory);
        },
      );
    });

    test('should return CacheFailure when dataSource fails', () async {
      // Arrange
      when(() => mockLocalDataSource.addIncome(any()))
          .thenThrow(const CacheFailure('Cache error'));

      // Act
      final result = await repository.addIncome(tIncome);

      // Assert
      verify(() => mockLocalDataSource.addIncome(any())).called(1);
      verifyNever(() => mockCategoryRepository.getCategoryById(any()));
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<CacheFailure>());
    });
  });

  group('updateIncome', () {
    test('should return Income with category when update is successful', () async {
      // Arrange
      when(() => mockLocalDataSource.updateIncome(any()))
          .thenAnswer((_) async => tIncomeModel);
      when(() => mockCategoryRepository.getCategoryById('cat1'))
          .thenAnswer((_) async => Right(tCategory));

      // Act
      final result = await repository.updateIncome(tIncome);

      // Assert
      verify(() => mockLocalDataSource.updateIncome(any())).called(1);
      expect(result.isRight(), true);
    });
  });

  group('getIncomes', () {
    test('should return list of IncomeModels from dataSource', () async {
      // Arrange
      when(() => mockLocalDataSource.getIncomes(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            categoryId: any(named: 'categoryId'),
            accountId: any(named: 'accountId'),
          )).thenAnswer((_) async => [tIncomeModel]);

      // Act
      final result = await repository.getIncomes(
        accountId: 'acc1',
        categoryId: 'cat1',
      );

      // Assert
      verify(() => mockLocalDataSource.getIncomes(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            categoryId: 'cat1',
            accountId: 'acc1',
          )).called(1);
      expect(result.isRight(), true);
      result.fold(
        (failure) => fail('Should not fail'),
        (models) {
          expect(models.length, 1);
          expect(models.first.id, tIncomeModel.id);
        },
      );
    });
  });

  group('deleteIncome', () {
    test('should return void when delete is successful', () async {
      // Arrange
      when(() => mockLocalDataSource.deleteIncome(any()))
          .thenAnswer((_) async {});

      // Act
      final result = await repository.deleteIncome('1');

      // Assert
      verify(() => mockLocalDataSource.deleteIncome('1')).called(1);
      expect(result.isRight(), true);
    });
  });

  group('getTotalIncomeForAccount', () {
    test('should return correct total amount', () async {
      // Arrange
      final incomeModel2 = IncomeModel(
          id: '2',
          title: 'Salary 2',
          amount: 1000.0,
          date: DateTime(2023, 10, 1),
          accountId: 'acc1',
      );

      when(() => mockLocalDataSource.getIncomes(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            categoryId: any(named: 'categoryId'),
            accountId: 'acc1',
          )).thenAnswer((_) async => [
            tIncomeModel,
            incomeModel2
          ]);

      // Act
      final result = await repository.getTotalIncomeForAccount('acc1');

      // Assert
      expect(result.isRight(), true);
      expect(result.getOrElse(() => 0.0), 6000.0);
    });
  });

  group('updateIncomeCategorization', () {
    test('should update income with new categorization', () async {
      // Arrange
      when(() => mockLocalDataSource.getIncomeById('1'))
          .thenAnswer((_) async => tIncomeModel);
      when(() => mockLocalDataSource.updateIncome(any()))
          .thenAnswer((_) async => tIncomeModel);

      // Act
      final result = await repository.updateIncomeCategorization(
        '1',
        'cat2',
        CategorizationStatus.categorized,
        0.9,
      );

      // Assert
      verify(() => mockLocalDataSource.getIncomeById('1')).called(1);
      verify(() => mockLocalDataSource.updateIncome(any())).called(1);
      expect(result.isRight(), true);
    });
  });

  group('reassignIncomesCategory', () {
    test('should update all incomes with old category id', () async {
      // Arrange
      final income1 = IncomeModel(
          id: '1', title: 'T1', amount: 10, date: DateTime.now(), accountId: 'a', categoryId: 'oldCat');
      final income2 = IncomeModel(
          id: '2', title: 'T2', amount: 20, date: DateTime.now(), accountId: 'a', categoryId: 'otherCat');
      final income3 = IncomeModel(
          id: '3', title: 'T3', amount: 30, date: DateTime.now(), accountId: 'a', categoryId: 'oldCat');

      when(() => mockLocalDataSource.getIncomes())
          .thenAnswer((_) async => [income1, income2, income3]);

      when(() => mockLocalDataSource.updateIncome(any()))
          .thenAnswer((_) async => tIncomeModel);

      // Act
      final result = await repository.reassignIncomesCategory('oldCat', 'newCat');

      // Assert
      verify(() => mockLocalDataSource.getIncomes()).called(1);
      // Should update income1 and income3 (2 times)
      verify(() => mockLocalDataSource.updateIncome(any())).called(2);
      expect(result.isRight(), true);
      expect(result.getOrElse(() => -1), 2);
    });
  });
}
