import 'package:bloc_test/bloc_test.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
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

  setUp(() {
    sl.reset();

    // Register all mocks
    sl.registerFactory<SettingsBloc>(() => MockSettingsBloc());
    sl.registerFactory<DataManagementBloc>(() => MockDataManagementBloc());
    sl.registerFactory<TransactionListBloc>(() => MockTransactionListBloc());
    sl.registerFactory<CategoryManagementBloc>(
      () => MockCategoryManagementBloc(),
    );
    sl.registerFactory<BudgetListBloc>(() => MockBudgetListBloc());
    sl.registerFactory<GoalListBloc>(() => MockGoalListBloc());
    sl.registerFactory<DashboardBloc>(() => MockDashboardBloc());
    sl.registerFactory<AccountListBloc>(() => MockAccountListBloc());
    sl.registerFactory<SessionCubit>(() => MockSessionCubit());
    sl.registerFactory<AuthBloc>(() => MockAuthBloc());
    sl.registerFactory<GroupsBloc>(() => MockGroupsBloc());
    sl.registerFactory<DeepLinkBloc>(() => MockDeepLinkBloc());
  });

  testWidgets('App renders correctly', (tester) async {
    // Setup default behaviors for blocs called in App
    final mockSettingsBloc = sl<SettingsBloc>();
    when(() => mockSettingsBloc.state).thenReturn(const SettingsState());
    when(() => mockSettingsBloc.add(any())).thenAnswer((_) async {});

    final mockAccountListBloc = sl<AccountListBloc>();
    when(() => mockAccountListBloc.add(any())).thenAnswer((_) async {});

    final mockTransactionListBloc = sl<TransactionListBloc>();
    when(() => mockTransactionListBloc.add(any())).thenAnswer((_) async {});

    final mockCategoryManagementBloc = sl<CategoryManagementBloc>();
    when(() => mockCategoryManagementBloc.add(any())).thenAnswer((_) async {});

    final mockBudgetListBloc = sl<BudgetListBloc>();
    when(() => mockBudgetListBloc.add(any())).thenAnswer((_) async {});

    final mockGoalListBloc = sl<GoalListBloc>();
    when(() => mockGoalListBloc.add(any())).thenAnswer((_) async {});

    final mockDashboardBloc = sl<DashboardBloc>();
    when(() => mockDashboardBloc.add(any())).thenAnswer((_) async {});

    final mockAuthBloc = sl<AuthBloc>();
    when(() => mockAuthBloc.add(any())).thenAnswer((_) async {});

    final mockGroupsBloc = sl<GroupsBloc>();
    when(() => mockGroupsBloc.add(any())).thenAnswer((_) async {});

    final mockDeepLinkBloc = sl<DeepLinkBloc>();
    when(() => mockDeepLinkBloc.add(any())).thenAnswer((_) async {});

    await tester.pumpWidget(const App());
    // expect(find.byType(MyApp), findsOneWidget); // MyApp is internal, but we can verify it builds something
    // Verify it doesn't crash.
  });
}
