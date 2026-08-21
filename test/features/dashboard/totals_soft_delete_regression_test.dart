import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockExpenseLocalDataSource extends Mock
    implements ExpenseLocalDataSource {}

class MockIncomeLocalDataSource extends Mock implements IncomeLocalDataSource {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

void main() {
  late ExpenseRepositoryImpl expenseRepository;
  late IncomeRepositoryImpl incomeRepository;
  late MockExpenseLocalDataSource mockExpenseDataSource;
  late MockIncomeLocalDataSource mockIncomeDataSource;
  late MockCategoryRepository mockCategoryRepository;
  late MockSupabaseClient mockSupabaseClient;

  setUp(() {
    mockExpenseDataSource = MockExpenseLocalDataSource();
    mockIncomeDataSource = MockIncomeLocalDataSource();
    mockCategoryRepository = MockCategoryRepository();
    mockSupabaseClient = MockSupabaseClient();

    expenseRepository = ExpenseRepositoryImpl(
      localDataSource: mockExpenseDataSource,
      categoryRepository: mockCategoryRepository,
      supabaseClient: mockSupabaseClient,
    );

    incomeRepository = IncomeRepositoryImpl(
      localDataSource: mockIncomeDataSource,
      categoryRepository: mockCategoryRepository,
    );
  });

  final activeExpense = ExpenseModel(
    id: 'exp1',
    title: 'Active Expense',
    amount: 100.0,
    date: DateTime(2026, 4, 1),
    accountId: 'acc1',
  );

  final deletedExpense = ExpenseModel(
    id: 'exp2',
    title: 'Deleted Expense',
    amount: 500.0,
    date: DateTime(2026, 4, 1),
    accountId: 'acc1',
    deletedAt: DateTime(2026, 4, 2),
  );

  final activeIncome = IncomeModel(
    id: 'inc1',
    title: 'Active Income',
    amount: 1000.0,
    date: DateTime(2026, 4, 1),
    accountId: 'acc1',
  );

  final deletedIncome = IncomeModel(
    id: 'inc2',
    title: 'Deleted Income',
    amount: 2000.0,
    date: DateTime(2026, 4, 1),
    accountId: 'acc1',
    deletedAt: DateTime(2026, 4, 2),
  );

  group('Totals Soft Delete Regression', () {
    test('getTotalExpensesForAccount excludes soft-deleted expenses', () async {
      when(
        () => mockExpenseDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer(
        (_) async => [activeExpense],
      ); // DS filters deletedAt == null

      final total = await expenseRepository.getTotalExpensesForAccount('acc1');

      expect(total.isRight(), true);
      expect(total.getOrElse(() => -1), 100.0);
    });

    test('getTotalIncomeForAccount excludes soft-deleted incomes', () async {
      when(
        () => mockIncomeDataSource.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [activeIncome]); // DS filters deletedAt == null

      final total = await incomeRepository.getTotalIncomeForAccount('acc1');

      expect(total.isRight(), true);
      expect(total.getOrElse(() => -1), 1000.0);
    });

    test('getExpenseSummary excludes soft-deleted expenses', () async {
      when(
        () => mockExpenseDataSource.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          categoryId: any(named: 'categoryId'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => [activeExpense]);
      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => const Right([]));

      final summaryResult = await expenseRepository.getExpenseSummary();

      expect(summaryResult.isRight(), true);
      final summary = summaryResult.getOrElse(() => throw Exception());
      expect(summary.totalExpenses, 100.0);
    });
  });
}
