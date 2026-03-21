import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetFinancialOverviewUseCase useCase;
  late MockAssetAccountRepository mockAccountRepo;
  late MockIncomeRepository mockIncomeRepo;
  late MockExpenseRepository mockExpenseRepo;
  late MockBudgetRepository mockBudgetRepo;
  late MockGoalRepository mockGoalRepo;
  late MockReportRepository mockReportRepo;

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

  test('Benchmark Goal Sorting in GetFinancialOverviewUseCase', () async {
    final goals = List.generate(100, (i) {
      return Goal(
        id: 'goal_$i',
        name: 'Goal $i',
        targetAmount: 1000,
        totalSaved: (i % 1000).toDouble(),
        targetDate: i % 2 == 0
            ? DateTime(2023, 1, 1).add(Duration(days: i))
            : null,
        status: GoalStatus.active,
        createdAt: DateTime.now(),
      );
    });

    when(
      () => mockAccountRepo.getAssetAccounts(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockIncomeRepo.getTotalIncomeForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Right(0.0));
    when(
      () => mockExpenseRepo.getTotalExpensesForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Right(0.0));
    when(
      () => mockBudgetRepo.getBudgets(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () =>
          mockGoalRepo.getGoals(includeArchived: any(named: 'includeArchived')),
    ).thenAnswer((_) async => Right(goals));
    when(
      () => mockReportRepo.getRecentDailySpending(days: any(named: 'days')),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => mockReportRepo.getRecentDailyContributions(
        any(),
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => const Right([]));

    // Warmup
    await useCase(const GetFinancialOverviewParams());

    final stopwatch = Stopwatch()..start();
    const iterations = 5;
    for (int i = 0; i < iterations; i++) {
      await useCase(const GetFinancialOverviewParams());
    }
    stopwatch.stop();

    print(
      'BASELINE_RESULT: Average execution time over $iterations iterations with ${goals.length} goals: ${stopwatch.elapsedMilliseconds / iterations} ms',
    );
  });
}
