import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';

class MockExpenseRepo extends Mock implements ExpenseRepository {}

class MockIncomeRepo extends Mock implements IncomeRepository {}

class MockAccountRepo extends Mock implements AssetAccountRepository {}

class MockBudgetRepo extends Mock implements BudgetRepository {}

class MockGoalRepo extends Mock implements GoalRepository {}

class MockReportRepo extends Mock implements ReportRepository {}

void main() {
  late GetFinancialOverviewUseCase usecase;

  setUp(() {
    usecase = GetFinancialOverviewUseCase(
      expenseRepository: MockExpenseRepo(),
      incomeRepository: MockIncomeRepo(),
      accountRepository: MockAccountRepo(),
      budgetRepository: MockBudgetRepo(),
      goalRepository: MockGoalRepo(),
      reportRepository: MockReportRepo(),
    );
  });

  test('can be instantiated', () {
    expect(usecase, isNotNull);
  });
}
