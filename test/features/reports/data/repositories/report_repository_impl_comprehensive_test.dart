import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/entities/category_type.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
  late MockExpenseRepository mockExpenseRepository;
  late MockIncomeRepository mockIncomeRepository;
  late MockCategoryRepository mockCategoryRepository;
  late MockAssetAccountRepository mockAccountRepository;
  late MockBudgetRepository mockBudgetRepository;
  late MockGoalRepository mockGoalRepository;
  late MockGoalContributionRepository mockGoalContributionRepository;

  setUp(() {
    mockExpenseRepository = MockExpenseRepository();
    mockIncomeRepository = MockIncomeRepository();
    mockCategoryRepository = MockCategoryRepository();
    mockAccountRepository = MockAssetAccountRepository();
    mockBudgetRepository = MockBudgetRepository();
    mockGoalRepository = MockGoalRepository();
    mockGoalContributionRepository = MockGoalContributionRepository();

    repository = ReportRepositoryImpl(
      expenseRepository: mockExpenseRepository,
      incomeRepository: mockIncomeRepository,
      categoryRepository: mockCategoryRepository,
      accountRepository: mockAccountRepository,
      budgetRepository: mockBudgetRepository,
      goalRepository: mockGoalRepository,
      goalContributionRepository: mockGoalContributionRepository,
    );

    // Register fallback values
    registerFallbackValue(DateTime(2023));
  });

  const tCategoryId = 'cat1';
  const tCategoryName = 'Food';
  const tCategoryColor = '#FFFFFF';
  const tCategory = Category(
    id: tCategoryId,
    name: tCategoryName,
    iconName: 'icon',
    colorHex: tCategoryColor,
    type: CategoryType.expense,
    isCustom: false,
  );

  final tExpense1 = ExpenseModel(
    id: 'exp1',
    amount: 100.0,
    date: DateTime(2023, 10, 15),
    categoryId: tCategoryId,
    accountId: 'acc1',
    title: 'Lunch',
  );

  final tExpense2 = ExpenseModel(
    id: 'exp2',
    amount: 50.0,
    date: DateTime(2023, 10, 16),
    categoryId: tCategoryId,
    accountId: 'acc1',
    title: 'Dinner',
  );

  // Uncategorized Expense
  final tExpenseUncategorized = ExpenseModel(
    id: 'exp3',
    amount: 25.0,
    date: DateTime(2023, 10, 17),
    categoryId: null,
    accountId: 'acc1',
    title: 'Snack',
  );

  // Previous Period Expense
  final tExpensePrev = ExpenseModel(
    id: 'expPrev',
    amount: 80.0,
    date: DateTime(2023, 9, 15), // Previous month
    categoryId: tCategoryId,
    accountId: 'acc1',
    title: 'Old Lunch',
  );

  // Income
  final tIncome1 = IncomeModel(
    id: 'inc1',
    amount: 1000.0,
    date: DateTime(2023, 10, 1),
    categoryId: 'inc_cat',
    accountId: 'acc1',
    title: 'Salary',
  );

  final tIncomePrev = IncomeModel(
    id: 'incPrev',
    amount: 900.0,
    date: DateTime(2023, 9, 1),
    categoryId: 'inc_cat',
    accountId: 'acc1',
    title: 'Old Salary',
  );

  // Budgets
  final tBudget1 = Budget(
    id: 'b1',
    name: 'Food',
    type: BudgetType.categorySpecific,
    categoryIds: [tCategoryId],
    targetAmount: 200.0,
    period: BudgetPeriodType.recurringMonthly,
    startDate: DateTime(2023, 1, 1),
    createdAt: DateTime(2023, 1, 1),
  );

  final tBudget2 = Budget(
    id: 'b2',
    name: 'Overall',
    type: BudgetType.overall,
    targetAmount: 500.0,
    period: BudgetPeriodType.recurringMonthly,
    startDate: DateTime(2023, 1, 1),
    createdAt: DateTime(2023, 1, 1),
  );

  // Goals
  final tGoal = Goal(
    id: 'g1',
    name: 'Vacation',
    targetAmount: 1000.0,
    totalSaved: 200.0,
    targetDate: DateTime.now().add(const Duration(days: 100)),
    createdAt: DateTime.now(),
    status: GoalStatus.active,
  );

  final tGoalContribution = GoalContribution(
    id: 'gc1',
    goalId: 'g1',
    amount: 50.0,
    date: DateTime.now().subtract(const Duration(days: 2)),
    note: 'Savings',
    createdAt: DateTime.now(),
  );

  group('getSpendingByCategory', () {
    test('should return correct spending data for current period', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 1);
      final endDate = DateTime(2023, 10, 31);

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Right([tExpense1, tExpense2, tExpenseUncategorized]));

      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => const Right([tCategory]));

      // Act
      final result = await repository.getSpendingByCategory(
        startDate: startDate,
        endDate: endDate,
        transactionType: TransactionType.expense,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      expect(report.totalSpending.currentValue, 175.0); // 100 + 50 + 25
      expect(report.spendingByCategory.length, 2); // Food, Uncategorized

      final foodData = report.spendingByCategory.firstWhere(
        (d) => d.categoryId == tCategoryId,
      );
      expect(foodData.currentTotalAmount, 150.0);
      expect(foodData.percentage, closeTo(0.857, 0.001)); // 150 / 175

      final uncategorizedData = report.spendingByCategory.firstWhere(
        (d) => d.categoryId == 'uncategorized',
      );
      expect(uncategorizedData.currentTotalAmount, 25.0);
      expect(uncategorizedData.percentage, closeTo(0.142, 0.001)); // 25 / 175
    });

    test('should return comparison data when compareToPrevious is true', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 1);
      final endDate = DateTime(2023, 10, 31);

      // Mock repository behavior for different date ranges
      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((invocation) async {
        final start = invocation.namedArguments[#startDate] as DateTime;
        if (start.month == 10) {
          return Right([tExpense1]); // 100.0
        } else {
          return Right([tExpensePrev]); // 80.0
        }
      });

      when(
        () => mockCategoryRepository.getAllCategories(),
      ).thenAnswer((_) async => const Right([tCategory]));

      // Act
      final result = await repository.getSpendingByCategory(
        startDate: startDate,
        endDate: endDate,
        transactionType: TransactionType.expense,
        compareToPrevious: true,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      expect(report.totalSpending.currentValue, 100.0);
      expect(report.totalSpending.previousValue, 80.0);
    });

    test(
      'should return empty report when transactionType is Income (as per logic)',
      () async {
        // Arrange
        final startDate = DateTime(2023, 10, 1);
        final endDate = DateTime(2023, 10, 31);

        // Act
        final result = await repository.getSpendingByCategory(
          startDate: startDate,
          endDate: endDate,
          transactionType: TransactionType.income,
        );

        // Assert
        expect(result.isRight(), true);
        final report = result.getOrElse(() => throw Exception('Failed'));
        expect(report.totalSpending.currentValue, 0.0);
        expect(report.spendingByCategory, isEmpty);
      },
    );
  });

  group('getSpendingOverTime', () {
    test('should aggregate spending correctly for daily granularity', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 15);
      final endDate = DateTime(2023, 10, 17);

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Right([tExpense1, tExpense2, tExpenseUncategorized]));

      // Act
      final result = await repository.getSpendingOverTime(
        startDate: startDate,
        endDate: endDate,
        granularity: TimeSeriesGranularity.daily,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      expect(report.spendingData.length, 3);

      // Order is sorted by date
      expect(report.spendingData[0].currentAmount, 100.0); // Oct 15
      expect(report.spendingData[1].currentAmount, 50.0); // Oct 16
      expect(report.spendingData[2].currentAmount, 25.0); // Oct 17
    });

    test('should return comparison data when compareToPrevious is true', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 1);
      final endDate = DateTime(2023, 10, 31);

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((invocation) async {
        final start = invocation.namedArguments[#startDate] as DateTime;
        if (start.month == 10) {
          return Right([tExpense1]); // 100.0 on Oct 15
        } else {
          return Right([tExpensePrev]); // 80.0 on Sep 15
        }
      });

      // Act
      final result = await repository.getSpendingOverTime(
        startDate: startDate,
        endDate: endDate,
        granularity: TimeSeriesGranularity.monthly,
        compareToPrevious: true,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      // Monthly granularity -> grouped to 1st of month
      // Current: Oct 1, Previous: Sep 1
      expect(report.spendingData.first.currentAmount, 100.0);
      expect(report.spendingData.first.amount.previousValue, null);
    });
  });

  group('getIncomeVsExpense', () {
    test('should aggregate income and expense correctly', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 1);
      final endDate = DateTime(2023, 10, 31);

      // Mock both repositories
      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Right([tExpense1, tExpense2])); // 150 total expense

      when(
        () => mockIncomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Right([tIncome1])); // 1000 total income

      // Act
      final result = await repository.getIncomeVsExpense(
        startDate: startDate,
        endDate: endDate,
        periodType: IncomeExpensePeriodType.monthly,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      expect(report.periodData.length, 1);
      expect(report.periodData.first.currentTotalIncome, 1000.0);
      expect(report.periodData.first.currentTotalExpense, 150.0);
    });

    test('should return comparison data when compareToPrevious is true', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 1);
      final endDate = DateTime(2023, 10, 31);

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => const Right([])); // Simplify expense to 0 for this test

      when(
        () => mockIncomeRepository.getIncomes(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((invocation) async {
         final start = invocation.namedArguments[#startDate] as DateTime;
         if (start.month == 10) {
           return Right([tIncome1]); // 1000
         } else {
           return Right([tIncomePrev]); // 900
         }
      });

      // Act
      final result = await repository.getIncomeVsExpense(
        startDate: startDate,
        endDate: endDate,
        periodType: IncomeExpensePeriodType.monthly,
        compareToPrevious: true,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      // Similar to time series, `periodStart` is used as key.
      // Oct 1 vs Sep 1.
      expect(report.periodData.first.currentTotalIncome, 1000.0);
      // Previous value will be null because keys don't match
      expect(report.periodData.first.totalIncome.previousValue, null);
    });
  });

  group('getBudgetPerformance', () {
    test('should calculate budget performance correctly for multiple budgets', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 1);
      final endDate = DateTime(2023, 10, 31);

      when(() => mockBudgetRepository.getBudgets())
          .thenAnswer((_) async => Right([tBudget1, tBudget2]));

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((_) async => Right([tExpense1, tExpense2, tExpenseUncategorized]));

      // Act
      final result = await repository.getBudgetPerformance(
        startDate: startDate,
        endDate: endDate,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      expect(report.performanceData.length, 2);

      // Food Budget: Only tCategoryId expenses (100 + 50 = 150)
      final foodPerf = report.performanceData.firstWhere(
        (p) => p.budget.name == 'Food',
      );
      expect(foodPerf.actualSpending.currentValue, 150.0);
      expect(foodPerf.varianceAmount.currentValue, 50.0); // 200 - 150
      expect(foodPerf.currentVariancePercent, 25.0); // 50 / 200 * 100

      // Overall Budget: All expenses (100 + 50 + 25 = 175)
      final overallPerf = report.performanceData.firstWhere(
        (p) => p.budget.name == 'Overall',
      );
      expect(overallPerf.actualSpending.currentValue, 175.0);
      expect(overallPerf.varianceAmount.currentValue, 325.0); // 500 - 175
      expect(overallPerf.currentVariancePercent, 65.0); // 325 / 500 * 100
    });

    test('should return previous performance when compareToPrevious is true', () async {
      // Arrange
      final startDate = DateTime(2023, 10, 1);
      final endDate = DateTime(2023, 10, 31);

      when(() => mockBudgetRepository.getBudgets())
          .thenAnswer((_) async => Right([tBudget1]));

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
        ),
      ).thenAnswer((invocation) async {
        final start = invocation.namedArguments[#startDate] as DateTime;
        if (start.month == 10) {
          return Right([tExpense1]); // 100.0
        } else {
          return Right([tExpensePrev]); // 80.0
        }
      });

      // Act
      final result = await repository.getBudgetPerformance(
        startDate: startDate,
        endDate: endDate,
        compareToPrevious: true,
      );

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      final perf = report.performanceData.first;
      expect(perf.actualSpending.currentValue, 100.0);
      expect(perf.actualSpending.previousValue, 80.0);

      // Previous Variance: 200 - 80 = 120
      expect(perf.varianceAmount.previousValue, 120.0);
      // Previous Variance %: 120 / 200 * 100 = 60
      expect(perf.previousVariancePercent, 60.0);
    });
  });

  group('getGoalProgress', () {
    test('should calculate goal progress and pacing', () async {
      // Arrange
      when(
        () => mockGoalRepository.getGoals(includeArchived: false),
      ).thenAnswer((_) async => Right([tGoal]));

      when(
        () => mockGoalContributionRepository.getAllContributions(),
      ).thenAnswer((_) async => Right([tGoalContribution]));

      // Act
      final result = await repository.getGoalProgress();

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));

      expect(report.progressData.length, 1);
      final data = report.progressData.first;
      expect(data.goal.id, tGoal.id);
      expect(data.contributions.length, 1);
      expect(data.contributions.first.amount, 50.0);

      // Check Pacing
      // 800 remaining, 100 days (approx)
      // daily ~ 8.0
      expect(data.requiredDailySaving, greaterThan(0));
      expect(data.requiredMonthlySaving, greaterThan(0));
    });

    test('should return empty if no goals found', () async {
      // Arrange
      when(
        () => mockGoalRepository.getGoals(includeArchived: false),
      ).thenAnswer((_) async => const Right([]));

      // Act
      final result = await repository.getGoalProgress();

      // Assert
      expect(result.isRight(), true);
      final report = result.getOrElse(() => throw Exception('Failed'));
      expect(report.progressData, isEmpty);
    });
  });

  group('getRecentDailySpending', () {
    test('should return 7 days of spending data (filled with 0s)', () async {
      // Arrange
      final now = DateTime.now();
      // Mock expense for today
      final tExpenseToday = ExpenseModel(
        id: 'today',
        amount: 20.0,
        date: now,
        categoryId: tCategoryId,
        accountId: 'acc1',
        title: 'Today',
      );

      when(
        () => mockExpenseRepository.getExpenses(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          accountId: any(named: 'accountId'),
          categoryId: any(named: 'categoryId'),
        ),
      ).thenAnswer((_) async => Right([tExpenseToday]));

      // Act
      final result = await repository.getRecentDailySpending(days: 7);

      // Assert
      expect(result.isRight(), true);
      final data = result.getOrElse(() => throw Exception('Failed'));
      expect(data.length, 7);

      // Last item should be today (or matching date logic)
      final lastPoint = data.last;
      expect(lastPoint.currentAmount, 20.0);

      // Previous days should be 0
      expect(data.first.currentAmount, 0.0);
    });
  });
}
