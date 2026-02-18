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

class FakeIncomeModel extends Fake implements IncomeModel {}

void main() {
  late IncomeRepositoryImpl repository;
  late MockIncomeLocalDataSource mockLocalDataSource;
  late MockCategoryRepository mockCategoryRepository;

  setUpAll(() {
    registerFallbackValue(FakeIncomeModel());
  });

  setUp(() {
    mockLocalDataSource = MockIncomeLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();

    // Inject dependency directly via constructor
    repository = IncomeRepositoryImpl(
      localDataSource: mockLocalDataSource,
      categoryRepository: mockCategoryRepository,
    );
  });

  const tCategory = Category(
    id: 'cat1',
    name: 'Salary',
    iconName: 'work',
    colorHex: '#000000',
    type: CategoryType.income,
    isCustom: false,
  );

  final tIncomeModel = IncomeModel(
    id: '1',
    title: 'Paycheck',
    amount: 5000.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    categoryId: 'cat1',
    categorizationStatusValue: 'categorized',
    confidenceScoreValue: 1.0,
  );

  final tIncome = Income(
    id: '1',
    title: 'Paycheck',
    amount: 5000.0,
    date: DateTime(2024, 1, 1),
    accountId: 'acc1',
    category: tCategory,
    status: CategorizationStatus.categorized,
    confidenceScore: 1.0,
  );

  group('addIncome', () {
    test(
      'should return hydrated Income when data source call is successful',
      () async {
        // Arrange
        when(
          () => mockLocalDataSource.addIncome(any()),
        ).thenAnswer((_) async => tIncomeModel);
        when(
          () => mockCategoryRepository.getCategoryById(any()),
        ).thenAnswer((_) async => const Right(tCategory));

        // Act
        final result = await repository.addIncome(tIncome);

        // Assert
        verify(
          () => mockLocalDataSource.addIncome(any<IncomeModel>()),
        ).called(1);
        verify(() => mockCategoryRepository.getCategoryById('cat1')).called(1);
        expect(result, Right(tIncome));
      },
    );

    test(
      'should return CacheFailure when data source throws CacheFailure',
      () async {
        // Arrange
        when(
          () => mockLocalDataSource.addIncome(any()),
        ).thenThrow(const CacheFailure('Hive Error'));

        // Act
        final result = await repository.addIncome(tIncome);

        // Assert
        expect(result, const Left(CacheFailure('Hive Error')));
      },
    );
  });

  group('deleteIncome', () {
    test('should return void when delete is successful', () async {
      // Arrange
      when(
        () => mockLocalDataSource.deleteIncome(any()),
      ).thenAnswer((_) async => Future.value());

      // Act
      final result = await repository.deleteIncome('1');

      // Assert
      verify(() => mockLocalDataSource.deleteIncome('1')).called(1);
      expect(result, const Right(null));
    });

    test('should return CacheFailure when delete fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.deleteIncome(any()),
      ).thenThrow(const CacheFailure('Delete Error'));

      // Act
      final result = await repository.deleteIncome('1');

      // Assert
      expect(result, const Left(CacheFailure('Delete Error')));
    });
  });

  group('getIncomes', () {
    test('should return list of IncomeModels from data source', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [tIncomeModel]);

      // Act
      final result = await repository.getIncomes();

      // Assert
      verify(
        () => mockLocalDataSource.getIncomes(
          startDate: null,
          endDate: null,
          categoryId: null,
          accountId: null,
        ),
      ).called(1);

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('should be right'),
        (r) => expect(r, [tIncomeModel]),
      );
    });

    test('should return CacheFailure when getting incomes fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(const CacheFailure('Fetch Error'));

      // Act
      final result = await repository.getIncomes();

      // Assert
      expect(result, const Left(CacheFailure('Fetch Error')));
    });
  });

  group('updateIncome', () {
    test('should return updated Income when successful', () async {
      // Arrange
      when(
        () => mockLocalDataSource.updateIncome(any()),
      ).thenAnswer((_) async => tIncomeModel);
      when(
        () => mockCategoryRepository.getCategoryById(any()),
      ).thenAnswer((_) async => const Right(tCategory));

      // Act
      final result = await repository.updateIncome(tIncome);

      // Assert
      verify(
        () => mockLocalDataSource.updateIncome(any<IncomeModel>()),
      ).called(1);
      expect(result, Right(tIncome));
    });

    test('should return CacheFailure when update fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.updateIncome(any()),
      ).thenThrow(const CacheFailure('Update Error'));

      // Act
      final result = await repository.updateIncome(tIncome);

      // Assert
      expect(result, const Left(CacheFailure('Update Error')));
    });
  });

  group('updateIncomeCategorization', () {
    test('should update income categorization successfully', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getIncomeById(any()),
      ).thenAnswer((_) async => tIncomeModel);
      when(
        () => mockLocalDataSource.updateIncome(any()),
      ).thenAnswer((_) async => tIncomeModel);

      // Act
      final result = await repository.updateIncomeCategorization(
        '1',
        'cat2',
        CategorizationStatus.needsReview,
        0.8,
      );

      // Assert
      verify(() => mockLocalDataSource.getIncomeById('1')).called(1);
      verify(
        () => mockLocalDataSource.updateIncome(any<IncomeModel>()),
      ).called(1);
      expect(result, const Right(null));
    });

    test('should return CacheFailure if income not found', () async {
      // Arrange
      when(
        () => mockLocalDataSource.getIncomeById(any()),
      ).thenAnswer((_) async => null);

      // Act
      final result = await repository.updateIncomeCategorization(
        '1',
        'cat2',
        CategorizationStatus.needsReview,
        0.8,
      );

      // Assert
      expect(result, const Left(CacheFailure("Income not found.")));
      verifyNever(() => mockLocalDataSource.updateIncome(any()));
    });
  });
}
