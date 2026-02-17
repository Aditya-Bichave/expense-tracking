
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
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
  late MockAssetAccountRepository mockAccountRepository;
  late MockIncomeRepository mockIncomeRepository;
  late MockExpenseRepository mockExpenseRepository;
  late MockBudgetRepository mockBudgetRepository;
  late MockGoalRepository mockGoalRepository;
  late MockReportRepository mockReportRepository;

  setUpAll(() {
    // Mock ServiceLocator
    final getIt = GetIt.instance;
    mockReportRepository = MockReportRepository();
    getIt.registerLazySingleton<ReportRepository>(() => mockReportRepository);
  });

  tearDownAll(() {
    GetIt.instance.reset();
  });

  setUp(() {
    mockAccountRepository = MockAssetAccountRepository();
    mockIncomeRepository = MockIncomeRepository();
    mockExpenseRepository = MockExpenseRepository();
    mockBudgetRepository = MockBudgetRepository();
    mockGoalRepository = MockGoalRepository();

    useCase = GetFinancialOverviewUseCase(
      accountRepository: mockAccountRepository,
      incomeRepository: mockIncomeRepository,
      expenseRepository: mockExpenseRepository,
      budgetRepository: mockBudgetRepository,
      goalRepository: mockGoalRepository,
    );
  });

  const tParams = GetFinancialOverviewParams();

  const tAccount = AssetAccount(
    id: '1',
    name: 'Cash',
    type: AssetType.cash,
    currentBalance: 1000.0,
  );

  test('should return financial overview when all repositories succeed', () async {
    // arrange
    when(() => mockAccountRepository.getAssetAccounts())
        .thenAnswer((_) async => Right([tAccount]));
    when(
      () => mockIncomeRepository.getTotalIncomeForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Right(2000.0));
    when(
      () => mockExpenseRepository.getTotalExpensesForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => const Right(500.0));
    when(() => mockBudgetRepository.getBudgets())
        .thenAnswer((_) async => const Right([]));
    when(() => mockGoalRepository.getGoals(includeArchived: false))
        .thenAnswer((_) async => const Right([]));
    when(() => mockReportRepository.getRecentDailySpending(days: any(named: 'days')))
        .thenAnswer((_) async => const Right([]));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result.isRight(), true);
    final overview = result.getOrElse(() => throw Exception());
    expect(overview.totalIncome, 2000.0);
    expect(overview.totalExpenses, 500.0);
    expect(overview.netFlow, 1500.0);
    expect(overview.overallBalance, 1000.0);
    expect(overview.accounts.length, 1);

    verify(() => mockAccountRepository.getAssetAccounts());
    verify(() => mockIncomeRepository.getTotalIncomeForAccount(any(), startDate: any(named: 'startDate'), endDate: any(named: 'endDate')));
    verify(() => mockExpenseRepository.getTotalExpensesForAccount(any(), startDate: any(named: 'startDate'), endDate: any(named: 'endDate')));
    verify(() => mockBudgetRepository.getBudgets());
    verify(() => mockGoalRepository.getGoals(includeArchived: false));
  });

  test('should return failure when one of the critical calls fails (e.g. accounts)', () async {
    // arrange
    when(() => mockAccountRepository.getAssetAccounts())
        .thenAnswer((_) async => Left(ServerFailure('Failed')));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Left(ServerFailure('Failed')));
  });
}
