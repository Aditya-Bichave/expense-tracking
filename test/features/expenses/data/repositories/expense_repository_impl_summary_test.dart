import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

void main() {
  late MockExpenseLocalDataSource mockDataSource;
  late MockCategoryRepository mockCategoryRepository;
  late ExpenseRepositoryImpl repository;

  setUp(() {
    mockDataSource = MockExpenseLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();
    repository = ExpenseRepositoryImpl(
      localDataSource: mockDataSource,
      categoryRepository: mockCategoryRepository,
    );
  });

  const tCategoryId1 = 'c1';
  const tCategoryId2 = 'c2';
  const tCategoryName1 = 'Food';
  const tCategoryName2 = 'Transport';

  final tCategory1 = Category(
    id: tCategoryId1,
    name: tCategoryName1,
    iconName: 'food',
    colorHex: '#FF0000',
    type: CategoryType.expense,
    isCustom: false,
  );
  final tCategory2 = Category(
    id: tCategoryId2,
    name: tCategoryName2,
    iconName: 'transport',
    colorHex: '#00FF00',
    type: CategoryType.expense,
    isCustom: false,
  );

  final tExpense1 = ExpenseModel(
    id: '1',
    title: 'Burger',
    amount: 10.0,
    date: DateTime(2023, 1, 1),
    accountId: 'a1',
    categoryId: tCategoryId1,
    categorizationStatusValue: 'uncategorized',
  );
  final tExpense2 = ExpenseModel(
    id: '2',
    title: 'Bus',
    amount: 5.0,
    date: DateTime(2023, 1, 2),
    accountId: 'a1',
    categoryId: tCategoryId2,
    categorizationStatusValue: 'uncategorized',
  );
  final tExpense3 = ExpenseModel(
    id: '3',
    title: 'Pizza',
    amount: 15.0,
    date: DateTime(2023, 1, 3),
    accountId: 'a1',
    categoryId: tCategoryId1,
    categorizationStatusValue: 'uncategorized',
  );
  final tExpense4 = ExpenseModel(
    id: '4',
    title: 'Unknown',
    amount: 20.0,
    date: DateTime(2023, 1, 4),
    accountId: 'a1',
    categoryId: 'c3', // Non-existent category
    categorizationStatusValue: 'uncategorized',
  );
  final tExpense5 = ExpenseModel(
    id: '5',
    title: 'No Cat',
    amount: 30.0,
    date: DateTime(2023, 1, 5),
    accountId: 'a1',
    categoryId: null, // Null category
    categorizationStatusValue: 'uncategorized',
  );

  test('getExpenseSummary returns correct summary', () async {
    // Arrange
    when(() => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer(
        (_) async => [tExpense1, tExpense2, tExpense3, tExpense4, tExpense5]);

    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => Right([tCategory1, tCategory2]));

    // Act
    final result = await repository.getExpenseSummary();

    // Assert
    expect(result.isRight(), true);
    final summary = result.getOrElse(() => throw Exception());

    // Total: 10 + 5 + 15 + 20 + 30 = 80
    expect(summary.totalExpenses, 80.0);

    // Breakdown:
    // Food: 10 + 15 = 25
    // Transport: 5
    // Uncategorized (Unknown + No Cat): 20 + 30 = 50

    // Sort logic: By value descending.
    // 50 (Uncategorized) > 25 (Food) > 5 (Transport)

    expect(summary.categoryBreakdown.length, 3);

    // Map iteration order is guaranteed to be insertion order in Dart if LinkedHashMap (default).
    // The implementation sorts and creates a new map.
    // So keys should be ordered.
    final keys = summary.categoryBreakdown.keys.toList();
    expect(keys, ['Uncategorized', 'Food', 'Transport']);

    expect(summary.categoryBreakdown['Food'], 25.0);
    expect(summary.categoryBreakdown['Transport'], 5.0);
    expect(summary.categoryBreakdown['Uncategorized'], 50.0);
  });

  test('getExpenseSummary returns failure when datasource fails', () async {
    when(() => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenThrow(const CacheFailure('Error'));

    final result = await repository.getExpenseSummary();

    expect(result.isLeft(), true);
  });

  test('getExpenseSummary returns failure when category repo fails', () async {
    when(() => mockDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        )).thenAnswer((_) async => []);

    when(() => mockCategoryRepository.getAllCategories())
        .thenAnswer((_) async => const Left(CacheFailure('Cat Error')));

    final result = await repository.getExpenseSummary();

    expect(result.isLeft(), true);
  });
}
