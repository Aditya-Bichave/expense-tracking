import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockExpenseLocalDataSource mockDataSource;
  late MockCategoryRepository mockCategoryRepository;
  late MockSupabaseClient mockSupabaseClient;
  late ExpenseRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      ExpenseModel(
        id: 'dummy',
        title: 'dummy',
        amount: 0,
        date: DateTime(2000),
        accountId: 'dummy',
        categorizationStatusValue: 'uncategorized',
      ),
    );
  });

  setUp(() {
    mockDataSource = MockExpenseLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();
    mockSupabaseClient = MockSupabaseClient();
    repository = ExpenseRepositoryImpl(
      localDataSource: mockDataSource,
      categoryRepository: mockCategoryRepository,
      supabaseClient: mockSupabaseClient,
    );
  });

  final model1 = ExpenseModel(
    id: '1',
    title: 'Coffee',
    amount: 3.0,
    date: DateTime(2024, 1, 1),
    accountId: 'a1',
    categorizationStatusValue: 'uncategorized',
  );
  final model2 = ExpenseModel(
    id: '2',
    title: 'Sandwich',
    amount: 5.0,
    date: DateTime(2024, 1, 3),
    accountId: 'a1',
    categorizationStatusValue: 'uncategorized',
  );
  final model3 = ExpenseModel(
    id: '3',
    title: 'Tea',
    amount: 2.0,
    date: DateTime(2024, 1, 2),
    accountId: 'a2',
    categorizationStatusValue: 'uncategorized',
  );

  test('returns sorted expenses from data source', () async {
    when(
      () => mockDataSource.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => [model1, model2, model3]);

    final result = await repository.getExpenses(
      startDate: DateTime(2024, 1, 1),
      endDate: DateTime(2024, 1, 31),
      categoryId: 'c1',
      accountId: 'a1',
    );

    expect(result.isRight(), isTrue);
    final models = result.getOrElse(() => []);
    expect(models.map((m) => m.id), ['2', '3', '1']);
    verify(
      () => mockDataSource.getExpenses(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        categoryId: 'c1',
        accountId: 'a1',
      ),
    ).called(1);
  });

  test('propagates CacheFailure from data source', () async {
    when(
      () => mockDataSource.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenThrow(const CacheFailure('cache error'));

    final result = await repository.getExpenses();

    expect(result.isLeft(), isTrue);
    result.fold(
      (failure) => expect(failure, const CacheFailure('cache error')),
      (_) => fail('should not return Right'),
    );
  });

  test(
    'propagates UnexpectedFailure from data source on unknown exception',
    () async {
      when(
        () => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(Exception('Unknown Error'));

      final result = await repository.getExpenses();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('should not return Right'),
      );
    },
  );

  test('passes category filter to data source', () async {
    when(
      () => mockDataSource.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => [model1]);

    await repository.getExpenses(categoryId: 'c1');

    verify(
      () => mockDataSource.getExpenses(
        startDate: null,
        endDate: null,
        categoryId: 'c1',
        accountId: null,
      ),
    ).called(1);
  });

  test('passes account filter to data source', () async {
    when(
      () => mockDataSource.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => [model1]);

    await repository.getExpenses(accountId: 'a1');

    verify(
      () => mockDataSource.getExpenses(
        startDate: null,
        endDate: null,
        categoryId: null,
        accountId: 'a1',
      ),
    ).called(1);
  });

  group('getExpenseById', () {
    test('returns Right(null) when not found', () async {
      when(
        () => mockDataSource.getExpenseById(any()),
      ).thenAnswer((_) async => null);

      final result = await repository.getExpenseById('1');

      expect(result, const Right(null));
      verify(() => mockDataSource.getExpenseById('1')).called(1);
    });

    test('returns Right(Expense) when found', () async {
      when(
        () => mockDataSource.getExpenseById(any()),
      ).thenAnswer((_) async => model1);

      final result = await repository.getExpenseById('1');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Should return Right'),
        (r) => expect(r?.id, '1'),
      );
    });

    test('returns CacheFailure on error', () async {
      when(
        () => mockDataSource.getExpenseById(any()),
      ).thenThrow(Exception('error'));

      final result = await repository.getExpenseById('1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<CacheFailure>()),
        (_) => fail('should not return Right'),
      );
    });
  });

  group('getTotalExpensesForAccount', () {
    test('returns total sum successfully', () async {
      when(
        () => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [model1, model2]); // 10.5 + 20.0 = 30.5

      final result = await repository.getTotalExpensesForAccount('a1');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return Right'), (r) => expect(r, 30.5));
    });

    test('returns UnexpectedFailure on Exception', () async {
      when(
        () => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(Exception('error'));

      final result = await repository.getTotalExpensesForAccount('a1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Should return Left'),
      );
    });
  });

  group('getExpenseSummary', () {
    test('returns summary successfully', () async {
      when(
        () => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [model1, model2]);

      final result = await repository.getExpenseSummary();

      expect(result.isRight(), isTrue);
    });

    test('returns UnexpectedFailure on Exception', () async {
      when(
        () => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(Exception('error'));

      final result = await repository.getExpenseSummary();

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Should return Left'),
      );
    });
  });

  group('updateExpenseCategorization', () {
    test('returns Right on success', () async {
      when(
        () => mockDataSource.getExpenseById(any()),
      ).thenAnswer((_) async => model1);
      when(
        () => mockDataSource.updateExpense(any()),
      ).thenAnswer((_) async => model1);

      final result = await repository.updateExpenseCategorization(
        '1',
        'c2',
        CategorizationStatus.categorized,
        0.9,
      );

      expect(result.isRight(), isTrue);
    });

    test('returns UnexpectedFailure on Exception', () async {
      when(
        () => mockDataSource.getExpenseById(any()),
      ).thenThrow(Exception('error'));

      final result = await repository.updateExpenseCategorization(
        '1',
        'c2',
        CategorizationStatus.categorized,
        0.9,
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Should return Left'),
      );
    });
  });

  group('reassignExpensesCategory', () {
    test('returns counts on success', () async {
      when(
        () => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [model1]);
      when(
        () => mockDataSource.updateExpense(any()),
      ).thenAnswer((_) async => model1);

      final result = await repository.reassignExpensesCategory('c1', 'c2');

      expect(result.isRight(), isTrue);
      result.fold((_) => fail('Should return Right'), (r) => expect(r, 1));
    });

    test('returns UnexpectedFailure on Exception', () async {
      when(
        () => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenThrow(Exception('error'));

      final result = await repository.reassignExpensesCategory('c1', 'c2');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('Should return Left'),
      );
    });
  });

  group('deleteExpense', () {
    test('returns Right(null) when successful', () async {
      when(() => mockDataSource.deleteExpense(any())).thenAnswer((_) async {});

      final result = await repository.deleteExpense('1');

      expect(result.isRight(), isTrue);
      verify(() => mockDataSource.deleteExpense('1')).called(1);
    });

    test('returns CacheFailure on CacheFailure', () async {
      when(
        () => mockDataSource.deleteExpense(any()),
      ).thenThrow(const CacheFailure('error'));

      final result = await repository.deleteExpense('1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, const CacheFailure('error')),
        (_) => fail('should not return Right'),
      );
    });

    test('returns UnexpectedFailure on generic Exception', () async {
      when(
        () => mockDataSource.deleteExpense(any()),
      ).thenThrow(Exception('error'));

      final result = await repository.deleteExpense('1');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<UnexpectedFailure>()),
        (_) => fail('should not return Right'),
      );
    });
  });

  test('passes date range to data source', () async {
    final start = DateTime(2024, 1, 1);
    final end = DateTime(2024, 1, 31);
    when(
      () => mockDataSource.getExpenses(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        categoryId: any(named: 'categoryId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async => [model1]);

    await repository.getExpenses(startDate: start, endDate: end);

    verify(
      () => mockDataSource.getExpenses(
        startDate: start,
        endDate: end,
        categoryId: null,
        accountId: null,
      ),
    ).called(1);
  });
}
