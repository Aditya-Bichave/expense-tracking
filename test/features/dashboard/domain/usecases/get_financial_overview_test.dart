import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockReportRepository extends Mock implements ReportRepository {}

class FakeBudget extends Fake implements Budget {}

void main() {
  late GetFinancialOverviewUseCase useCase;
  late MockAssetAccountRepository mockAccountRepo;
  late MockIncomeRepository mockIncomeRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockGoalRepository mockGoalRepo;
  late MockReportRepository mockReportRepo;

  setUpAll(() {
    registerFallbackValue(
      GetFinancialOverviewParams(
        startDate: DateTime.now(),
        endDate: DateTime.now(),
      ),
    );
    registerFallbackValue(FakeBudget());
  });

  setUp(() {
    mockAccountRepo = MockAssetAccountRepository();
    mockIncomeRepo = MockIncomeRepository();
    mockExpenseRepo = MockExpenseRepository();
    mockBudgetRepo = MockBudgetRepository();
    mockGoalRepo = MockGoalRepository();
    mockReportRepo = MockReportRepository();

    useCase = GetFinancialOverviewUseCase(
      accountRepository: mockAccountRepo,
      incomeRepository: mockIncomeRepo,
      expenseRepository: mockExpenseRepo,
      budgetRepository: mockBudgetRepo,
      goalRepository: mockGoalRepo,
      reportRepository: mockReportRepo,
    );
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);

  final tAccount = AssetAccount(
    id: '1',
    name: 'Bank',
    initialBalance: 100,
    currentBalance: 100,
    type: AssetType.bank,
  );

  final tBudget = Budget(
    id: '1',
    name: 'Budget',
    targetAmount: 100,
    type: BudgetType.overall,
    period: BudgetPeriodType.oneTime,
    startDate: tStartDate,
    endDate: tEndDate,
    createdAt: DateTime.now(),
  );

  final tGoal = Goal(
    id: '1',
    name: 'Goal',
    targetAmount: 100,
    totalSaved: 50,
    targetDate: DateTime.now(),
    iconName: 'icon',
    status: GoalStatus.active,
    createdAt: DateTime.now(),
  );

  final tSpendingData = [
    TimeSeriesDataPoint(
      date: DateTime(2023, 1, 1),
      amount: const ComparisonValue(currentValue: 10.0),
    ),
  ];

  test('should get financial overview successfully', () async {
    // Arrange
    when(
      () => mockAccountRepo.getAssetAccounts(),
    ).thenAnswer((_) async => Right([tAccount]));

    when(
      () => mockIncomeRepo.getTotalIncomeForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Right(200.0));

    when(
      () => mockExpenseRepo.getTotalExpensesForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Right(100.0));

    when(
      () => mockBudgetRepo.getBudgets(),
    ).thenAnswer((_) async => Right([tBudget]));
    when(
      () => mockBudgetRepo.calculateAmountSpent(
        budget: any(named: 'budget'),
        periodStart: any(named: 'periodStart'),
        periodEnd: any(named: 'periodEnd'),
      ),
    ).thenAnswer((_) async => const Right(50.0));

    when(
      () =>
          mockGoalRepo.getGoals(includeArchived: any(named: 'includeArchived')),
    ).thenAnswer((_) async => Right([tGoal]));

    when(
      () => mockReportRepo.getRecentDailySpending(days: any(named: 'days')),
    ).thenAnswer((_) async => Right(tSpendingData));

    when(
      () => mockReportRepo.getRecentDailyContributions(
        any(),
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => const Right([]));

    // Act
    final result = await useCase(
      GetFinancialOverviewParams(startDate: tStartDate, endDate: tEndDate),
    );

    // Assert
    expect(result.isRight(), isTrue);
    result.fold((failure) => fail('Should calculate correctly'), (overview) {
      expect(overview.totalIncome, 200.0);
      expect(overview.totalExpenses, 100.0);
      expect(overview.netFlow, 100.0);
      expect(overview.overallBalance, 100.0);
      expect(overview.accounts.length, 1);
      expect(overview.activeBudgetsSummary.length, 1);
      expect(overview.activeGoalsSummary.length, 1);
      expect(overview.recentSpendingSparkline, tSpendingData);
    });
  });
}
