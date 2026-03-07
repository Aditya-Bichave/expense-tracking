import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/main.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSettingsBloc extends MockBloc<SettingsEvent, SettingsState>
    implements SettingsBloc {}

class MockDataManagementBloc
    extends MockBloc<DataManagementEvent, DataManagementState>
    implements DataManagementBloc {}

class MockTransactionListBloc
    extends MockBloc<TransactionListEvent, TransactionListState>
    implements TransactionListBloc {}

class MockCategoryManagementBloc
    extends MockBloc<CategoryManagementEvent, CategoryManagementState>
    implements CategoryManagementBloc {}

class MockBudgetListBloc extends MockBloc<BudgetListEvent, BudgetListState>
    implements BudgetListBloc {}

class MockGoalListBloc extends MockBloc<GoalListEvent, GoalListState>
    implements GoalListBloc {}

class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState>
    implements DashboardBloc {}

class MockAccountListBloc extends MockBloc<AccountListEvent, AccountListState>
    implements AccountListBloc {}

class MockSessionCubit extends MockBloc<void, SessionState>
    implements SessionCubit {}

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockGroupsBloc extends MockBloc<GroupsEvent, GroupsState>
    implements GroupsBloc {}

class MockDeepLinkBloc extends MockBloc<DeepLinkEvent, DeepLinkState>
    implements DeepLinkBloc {}

void main() {
  final sl = GetIt.instance;

  late MockSettingsBloc settingsBloc;
  late MockDataManagementBloc dataManagementBloc;
  late MockTransactionListBloc transactionListBloc;
  late MockCategoryManagementBloc categoryManagementBloc;
  late MockBudgetListBloc budgetListBloc;
  late MockGoalListBloc goalListBloc;
  late MockDashboardBloc dashboardBloc;
  late MockAccountListBloc accountListBloc;
  late MockSessionCubit sessionCubit;
  late MockAuthBloc authBloc;
  late MockGroupsBloc groupsBloc;
  late MockDeepLinkBloc deepLinkBloc;

  setUp(() {
    sl.reset();

    settingsBloc = MockSettingsBloc();
    dataManagementBloc = MockDataManagementBloc();
    transactionListBloc = MockTransactionListBloc();
    categoryManagementBloc = MockCategoryManagementBloc();
    budgetListBloc = MockBudgetListBloc();
    goalListBloc = MockGoalListBloc();
    dashboardBloc = MockDashboardBloc();
    accountListBloc = MockAccountListBloc();
    sessionCubit = MockSessionCubit();
    authBloc = MockAuthBloc();
    groupsBloc = MockGroupsBloc();
    deepLinkBloc = MockDeepLinkBloc();

    when(() => settingsBloc.state).thenReturn(const SettingsState());
    when(
      () => dataManagementBloc.state,
    ).thenReturn(const DataManagementState());
    when(
      () => transactionListBloc.state,
    ).thenReturn(const TransactionListState());
    when(
      () => categoryManagementBloc.state,
    ).thenReturn(const CategoryManagementState());
    when(() => budgetListBloc.state).thenReturn(const BudgetListState());
    when(() => goalListBloc.state).thenReturn(const GoalListState());
    when(() => dashboardBloc.state).thenReturn(DashboardInitial());
    when(() => accountListBloc.state).thenReturn(const AccountListInitial());
    when(() => sessionCubit.state).thenReturn(SessionUnauthenticated());
    when(() => authBloc.state).thenReturn(AuthInitial());
    when(() => groupsBloc.state).thenReturn(GroupsInitial());
    when(() => deepLinkBloc.state).thenReturn(DeepLinkInitial());

    sl.registerSingleton<SettingsBloc>(settingsBloc);
    sl.registerSingleton<DataManagementBloc>(dataManagementBloc);
    sl.registerSingleton<TransactionListBloc>(transactionListBloc);
    sl.registerSingleton<CategoryManagementBloc>(categoryManagementBloc);
    sl.registerSingleton<BudgetListBloc>(budgetListBloc);
    sl.registerSingleton<GoalListBloc>(goalListBloc);
    sl.registerSingleton<DashboardBloc>(dashboardBloc);
    sl.registerSingleton<AccountListBloc>(accountListBloc);
    sl.registerSingleton<SessionCubit>(sessionCubit);
    sl.registerSingleton<AuthBloc>(authBloc);
    sl.registerSingleton<GroupsBloc>(groupsBloc);
    sl.registerSingleton<DeepLinkBloc>(deepLinkBloc);
  });

  testWidgets('App renders correctly', (tester) async {
    await tester.pumpWidget(const App());
    expect(tester.takeException(), isNull);
  });
}
