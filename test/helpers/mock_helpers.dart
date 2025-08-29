import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:flutter/widgets.dart';
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

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

// --- Fakes for registerFallbackValue ---
class _FakeBuildContext extends Fake implements BuildContext {}

class _FakeTransactionEntity extends Fake implements TransactionEntity {}

class _FakeLogContributionEvent extends Fake implements LogContributionEvent {}

class _FakeCategoryManagementEvent extends Fake
    implements CategoryManagementEvent {
  @override
  List<Object?> get props => [];
}

class _FakeCategoryManagementState extends Fake
    implements CategoryManagementState {
  @override
  List<Object?> get props => [];
}

class _FakeAddEditTransactionEvent extends Fake
    implements AddEditTransactionEvent {
  @override
  List<Object?> get props => [];
}

class _FakeAddEditTransactionState extends Fake
    implements AddEditTransactionState {
  @override
  List<Object?> get props => [];
}

class _FakeAccountListEvent extends Fake implements AccountListEvent {
  @override
  List<Object> get props => [];
}

class _FakeAccountListState extends Fake implements AccountListState {
  @override
  List<Object?> get props => [];
}

void registerFallbackValues() {
  registerFallbackValue(_FakeBuildContext());
  registerFallbackValue(_FakeTransactionEntity());
  registerFallbackValue(_FakeLogContributionEvent());
  registerFallbackValue(_FakeAccountListEvent());
  registerFallbackValue(_FakeAccountListState());
  registerFallbackValue(_FakeCategoryManagementEvent());
  registerFallbackValue(_FakeCategoryManagementState());
  registerFallbackValue(_FakeAddEditTransactionEvent());
  registerFallbackValue(_FakeAddEditTransactionState());
  registerFallbackValue(Category.uncategorized);
  registerFallbackValue(TransactionType.expense);
  registerFallbackValue(TransactionSortBy.date);
  registerFallbackValue(SortDirection.ascending);
  registerFallbackValue(BudgetType.overall);
  registerFallbackValue(BudgetPeriodType.recurringMonthly);
}

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
