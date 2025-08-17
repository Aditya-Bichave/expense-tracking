import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

// --- Mock Classes ---
class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockMerchantCategoryRepository extends Mock
    implements MerchantCategoryRepository {}

class MockUserHistoryRepository extends Mock implements UserHistoryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockReportRepository extends Mock implements ReportRepository {}

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

// --- Mock Registration Functions ---

Future<void> _register<T extends Object>(
    GetIt getIt, T Function() factory) async {
  if (getIt.isRegistered<T>()) {
    await getIt.unregister<T>();
  }
  getIt.registerLazySingleton<T>(factory);
}

// Registers mocks needed for the Accounts feature
Future<void> registerAccountsMocks(GetIt getIt) async {
  await _register<AssetAccountRepository>(
      getIt, () => MockAssetAccountRepository());
}

// Registers mocks needed for the Budgets feature
Future<void> registerBudgetsMocks(GetIt getIt) async {
  await _register<BudgetRepository>(getIt, () => MockBudgetRepository());
}

// Registers mocks needed for the Categories feature
Future<void> registerCategoriesMocks(GetIt getIt) async {
  await _register<CategoryRepository>(getIt, () => MockCategoryRepository());
  await _register<MerchantCategoryRepository>(
      getIt, () => MockMerchantCategoryRepository());
  await _register<UserHistoryRepository>(
      getIt, () => MockUserHistoryRepository());
}

// Registers mocks needed for the Transactions (Expense/Income) features
Future<void> registerTransactionsMocks(GetIt getIt) async {
  await _register<ExpenseRepository>(getIt, () => MockExpenseRepository());
  await _register<IncomeRepository>(getIt, () => MockIncomeRepository());
}

// Registers mocks needed for the Goals feature
Future<void> registerGoalsMocks(GetIt getIt) async {
  await _register<GoalRepository>(getIt, () => MockGoalRepository());
  await _register<GoalContributionRepository>(
      getIt, () => MockGoalContributionRepository());
}

// Registers mocks needed for the Recurring Transactions feature
Future<void> registerRecurringTransactionsMocks(GetIt getIt) async {
  await _register<RecurringTransactionRepository>(
      getIt, () => MockRecurringTransactionRepository());
}

// Registers mocks needed for the Reports feature
Future<void> registerReportsMocks(GetIt getIt) async {
  await _register<ReportRepository>(getIt, () => MockReportRepository());
}

// Registers mocks needed for the Settings feature
Future<void> registerSettingsMocks(GetIt getIt) async {
  await _register<SettingsRepository>(getIt, () => MockSettingsRepository());
  await _register<DataManagementRepository>(
      getIt, () => MockDataManagementRepository());
}
