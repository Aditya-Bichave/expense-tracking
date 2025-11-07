import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/liability_repository.dart';
import 'package:expense_tracker/features/dashboard/domain/entities/financial_overview.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';

class MockAccountRepo extends Mock implements AssetAccountRepository {}

class MockIncomeRepo extends Mock implements IncomeRepository {}

class MockExpenseRepo extends Mock implements ExpenseRepository {}

class MockBudgetRepo extends Mock implements BudgetRepository {}

class MockGoalRepo extends Mock implements GoalRepository {}

class MockReportRepo extends Mock implements ReportRepository {}

class MockLiabilityRepo extends Mock implements LiabilityRepository {}

void main() {
  late MockAccountRepo accountRepo;
  late MockIncomeRepo incomeRepo;
  late MockExpenseRepo expenseRepo;
  late MockBudgetRepo budgetRepo;
  late MockGoalRepo goalRepo;
  late MockReportRepo reportRepo;
  late MockLiabilityRepo liabilityRepo;
  late GetFinancialOverviewUseCase useCase;

  setUp(() {
    accountRepo = MockAccountRepo();
    incomeRepo = MockIncomeRepo();
    expenseRepo = MockExpenseRepo();
    budgetRepo = MockBudgetRepo();
    goalRepo = MockGoalRepo();
    reportRepo = MockReportRepo();
    liabilityRepo = MockLiabilityRepo();
    useCase = GetFinancialOverviewUseCase(
      accountRepository: accountRepo,
      liabilityRepository: liabilityRepo,
      incomeRepository: incomeRepo,
      expenseRepository: expenseRepo,
      budgetRepository: budgetRepo,
      goalRepository: goalRepo,
    );
  });

  test('propagates failure when income repository fails', () async {
    when(
      () => accountRepo.getAssetAccounts(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => liabilityRepo.getLiabilities(),
    ).thenAnswer((_) async => const Right([]));
    when(
      () => incomeRepo.getTotalIncomeForAccount(
        any(),
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
      ),
    ).thenAnswer((_) async => Left(ServerFailure('fail')));

    final result = await useCase(
      GetFinancialOverviewParams(
        startDate: DateTime(2024),
        endDate: DateTime(2024),
      ),
    );

    expect(result, isA<Left<Failure, FinancialOverview>>());
  });
}
