import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart';
import 'package:expense_tracker/features/categories/domain/entities/category.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_contribution_repository.dart';
import 'package:expense_tracker/features/goals/domain/repositories/goal_repository.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/log_contribution/log_contribution_bloc.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/add_expense/domain/repositories/add_expense_repository.dart';
import 'package:expense_tracker/features/add_expense/presentation/bloc/add_expense_wizard_state.dart';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

// --- Mock Classes ---
class MockAssetAccountRepository extends Mock
    implements AssetAccountRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockBudgetRepository extends Mock implements BudgetRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockMerchantCategoryRepository extends Mock
    implements MerchantCategoryRepository {}

class MockUserHistoryRepository extends Mock implements UserHistoryRepository {}

class MockExpenseRepository extends Mock implements ExpenseRepository {}

class MockGoalRepository extends Mock implements GoalRepository {}

class MockGoalContributionRepository extends Mock
    implements GoalContributionRepository {}

class MockGroupExpensesRepository extends Mock
    implements GroupExpensesRepository {}

class MockGroupsRepository extends Mock implements GroupsRepository {}

class MockIncomeRepository extends Mock implements IncomeRepository {}

class MockRecurringTransactionRepository extends Mock
    implements RecurringTransactionRepository {}

class MockReportRepository extends Mock implements ReportRepository {}

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

class MockSettingsRepository extends Mock implements SettingsRepository {}

class MockAddExpenseRepository extends Mock implements AddExpenseRepository {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockAddBudgetUseCase extends Mock implements AddBudgetUseCase {}

class MockUpdateBudgetUseCase extends Mock implements UpdateBudgetUseCase {}

class MockDemoModeService extends Mock implements DemoModeService {}

class MockHiveBudgetLocalDataSource extends Mock
    implements HiveBudgetLocalDataSource {}

class MockHiveGoalContributionLocalDataSource extends Mock
    implements HiveContributionLocalDataSource {}

class MockHiveGoalLocalDataSource extends Mock
    implements HiveGoalLocalDataSource {}

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

class _FakeAddExpenseWizardState extends Fake
    implements AddExpenseWizardState {}

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
  registerFallbackValue(_FakeAddExpenseWizardState());
  registerFallbackValue(Category.uncategorized);
  registerFallbackValue(TransactionType.expense);
  registerFallbackValue(TransactionSortBy.date);
  registerFallbackValue(SortDirection.ascending);
  registerFallbackValue(BudgetType.overall);
  registerFallbackValue(BudgetPeriodType.recurringMonthly);
}

// --- Mock Registration Functions ---

Future<void> _register<T extends Object>(
  GetIt getIt,
  T Function() factory,
) async {
  if (getIt.isRegistered<T>()) {
    await getIt.unregister<T>();
  }
  getIt.registerLazySingleton<T>(factory);
}

// Registers mocks needed for the Add Expense feature
Future<void> registerAddExpenseMocks(GetIt getIt) async {
  await _register<AddExpenseRepository>(
    getIt,
    () => MockAddExpenseRepository(),
  );
}

// Registers mocks needed for the Accounts feature
Future<void> registerAccountsMocks(GetIt getIt) async {
  await _register<AssetAccountRepository>(
    getIt,
    () => MockAssetAccountRepository(),
  );
}

// Registers mocks needed for the Auth feature
Future<void> registerAuthMocks(GetIt getIt) async {
  await _register<AuthRepository>(getIt, () => MockAuthRepository());
}

// Registers mocks needed for the Budgets feature
Future<void> registerBudgetsMocks(GetIt getIt) async {
  await _register<BudgetRepository>(getIt, () => MockBudgetRepository());
}

// Registers mocks needed for the Categories feature
Future<void> registerCategoriesMocks(GetIt getIt) async {
  await _register<CategoryRepository>(getIt, () => MockCategoryRepository());
  await _register<MerchantCategoryRepository>(
    getIt,
    () => MockMerchantCategoryRepository(),
  );
  await _register<UserHistoryRepository>(
    getIt,
    () => MockUserHistoryRepository(),
  );
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
    getIt,
    () => MockGoalContributionRepository(),
  );
}

// Registers mocks needed for the Group Expenses feature
Future<void> registerGroupExpensesMocks(GetIt getIt) async {
  await _register<GroupExpensesRepository>(
    getIt,
    () => MockGroupExpensesRepository(),
  );
}

// Registers mocks needed for the Groups feature
Future<void> registerGroupsMocks(GetIt getIt) async {
  await _register<GroupsRepository>(getIt, () => MockGroupsRepository());
}

// Registers mocks needed for the Recurring Transactions feature
Future<void> registerRecurringTransactionsMocks(GetIt getIt) async {
  await _register<RecurringTransactionRepository>(
    getIt,
    () => MockRecurringTransactionRepository(),
  );
}

// Registers mocks needed for the Reports feature
Future<void> registerReportsMocks(GetIt getIt) async {
  await _register<ReportRepository>(getIt, () => MockReportRepository());
}

// Registers mocks needed for the Settings feature
Future<void> registerSettingsMocks(GetIt getIt) async {
  await _register<SettingsRepository>(getIt, () => MockSettingsRepository());
  await _register<DataManagementRepository>(
    getIt,
    () => MockDataManagementRepository(),
  );
}
