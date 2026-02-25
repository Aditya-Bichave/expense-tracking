import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late MockExpenseLocalDataSource mockDataSource;
  late MockCategoryRepository mockCategoryRepository;
  late MockSupabaseClient mockSupabaseClient;
  late ExpenseRepositoryImpl repository;

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
