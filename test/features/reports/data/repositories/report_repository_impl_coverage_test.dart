import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

void main() {
  late ReportRepositoryImpl repository;
  late MockExpenseRepository mockExpenseRepo;
  late MockIncomeRepository mockIncomeRepo;
  late MockCategoryRepository mockCategoryRepo;
  late MockAssetAccountRepository mockAccountRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockGoalRepository mockGoalRepo;
  late MockGoalContributionRepository mockGoalContributionRepo;

  setUp(() {
    mockExpenseRepo = MockExpenseRepository();
    mockIncomeRepo = MockIncomeRepository();
    mockCategoryRepo = MockCategoryRepository();
    mockAccountRepo = MockAssetAccountRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockGoalRepo = MockGoalRepository();
    mockGoalContributionRepo = MockGoalContributionRepository();

    repository = ReportRepositoryImpl(
      expenseRepository: mockExpenseRepo,
      incomeRepository: mockIncomeRepo,
      categoryRepository: mockCategoryRepo,
      accountRepository: mockAccountRepo,
      budgetRepository: mockBudgetRepo,
      goalRepository: mockGoalRepo,
      goalContributionRepository: mockGoalContributionRepo,
    );
  });

  group('getSpendingOverTime missing granularity', () {
    test('weekly', () async {
      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer(
        (_) async => Right([
          ExpenseModel(
            id: '1',
            title: 'test',
            accountId: '1',
            amount: 10,
            date: DateTime(2024, 1, 1),
            categoryId: '1',
          ),
          ExpenseModel(
            id: '2',
            title: 'test',
            accountId: '1',
            amount: 10,
            date: DateTime(2024, 1, 2),
            categoryId: '1',
          ),
        ]),
      );

      when(
        () => mockIncomeRepo.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getSpendingOverTime(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        granularity: TimeSeriesGranularity.weekly,
      );
      expect(result.isRight(), true);
    });

    test('monthly', () async {
      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer(
        (_) async => Right([
          ExpenseModel(
            id: '1',
            title: 'test',
            accountId: '1',
            amount: 10,
            date: DateTime(2024, 1, 1),
            categoryId: '1',
          ),
        ]),
      );

      when(
        () => mockIncomeRepo.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getSpendingOverTime(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        granularity: TimeSeriesGranularity.monthly,
      );
      expect(result.isRight(), true);
    });
  });

  group('fetch failures', () {
    final tStartDate = DateTime(2024, 1, 1);
    final tEndDate = DateTime(2024, 1, 31);

    test('getSpendingByCategory should fail when expense fails', () async {
      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('Failed')));
      when(
        () => mockCategoryRepo.getAllCategories(),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getSpendingByCategory(
        startDate: tStartDate,
        endDate: tEndDate,
      );
      expect(result.isLeft(), true);
    });

    test('getSpendingByCategory should fail when category fails', () async {
      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Right([]));
      when(
        () => mockCategoryRepo.getAllCategories(),
      ).thenAnswer((_) async => const Left(CacheFailure('Failed')));

      final result = await repository.getSpendingByCategory(
        startDate: tStartDate,
        endDate: tEndDate,
      );
      expect(result.isLeft(), false);
    });

    test('getSpendingOverTime should fail when expense fails', () async {
      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('Failed')));

      final result = await repository.getSpendingOverTime(
        startDate: tStartDate,
        endDate: tEndDate,
        granularity: TimeSeriesGranularity.daily,
      );
      expect(result.isLeft(), true);
    });

    test('getIncomeVsExpense should fail when expense fails', () async {
      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Left(CacheFailure('Failed')));
      when(
        () => mockIncomeRepo.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getIncomeVsExpense(
        startDate: tStartDate,
        endDate: tEndDate,
        periodType: IncomeExpensePeriodType.monthly,
      );
      expect(result.isLeft(), true);
    });

    test('getBudgetPerformance should fail when budget fails', () async {
      when(
        () => mockBudgetRepo.getBudgets(),
      ).thenAnswer((_) async => const Left(CacheFailure('Failed')));
      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getBudgetPerformance(
        startDate: tStartDate,
        endDate: tEndDate,
      );
      expect(result.isLeft(), true);
    });
  });
  group('getSpendingOverTime income granularity', () {
    test('monthly income', () async {
      when(
        () => mockIncomeRepo.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer(
        (_) async => Right([
          IncomeModel(
            id: '3',
            title: 'test inc',
            accountId: '1',
            amount: 50,
            date: DateTime(2024, 1, 5),
            categoryId: '2',
          ),
        ]),
      );

      when(
        () => mockExpenseRepo.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => const Right([]));

      final result = await repository.getSpendingOverTime(
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 1, 31),
        granularity: TimeSeriesGranularity.monthly,
        transactionType: TransactionType.income,
      );
      expect(result.isRight(), true);
    });
  });
}
