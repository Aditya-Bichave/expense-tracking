import 'package:expense_tracker/app/root_app.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Wires the app-wide blocs above [RootApp].
///
/// Blocs marked `lazy: false` are needed to render the first frame — theme,
/// session and the initial dashboard/transaction lists — so they are built
/// eagerly instead of on first `read`.
class App extends StatelessWidget {
  const App({super.key, this.args = const []});

  final List<String> args;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(providers: _providers(), child: const RootApp());
  }

  List<BlocProvider> _providers() => [
    BlocProvider<SettingsBloc>(
      create: (_) => sl<SettingsBloc>()..add(const LoadSettings()),
      lazy: false,
    ),
    BlocProvider<DataManagementBloc>(create: (_) => sl<DataManagementBloc>()),
    BlocProvider<AccountListBloc>(
      create: (_) => sl<AccountListBloc>()..add(const LoadAccounts()),
    ),
    BlocProvider<TransactionListBloc>(
      create: (_) => sl<TransactionListBloc>()..add(const LoadTransactions()),
      lazy: false,
    ),
    BlocProvider<CategoryManagementBloc>(
      create: (_) => sl<CategoryManagementBloc>()..add(const LoadCategories()),
    ),
    BlocProvider<BudgetListBloc>(
      create: (_) => sl<BudgetListBloc>()..add(const LoadBudgets()),
    ),
    BlocProvider<GoalListBloc>(
      create: (_) => sl<GoalListBloc>()..add(const LoadGoals()),
    ),
    BlocProvider<DashboardBloc>(
      create: (_) => sl<DashboardBloc>()..add(const LoadDashboard()),
      lazy: false,
    ),
    BlocProvider<SessionCubit>(create: (_) => sl<SessionCubit>(), lazy: false),
    BlocProvider<AuthBloc>(
      create: (_) => sl<AuthBloc>()..add(AuthCheckStatus()),
      lazy: false,
    ),
    BlocProvider<GroupsBloc>(
      create: (_) => sl<GroupsBloc>()..add(LoadGroups()),
    ),
    BlocProvider<DeepLinkBloc>(
      create: (_) => sl<DeepLinkBloc>()..add(DeepLinkStarted(args: args)),
      lazy: false,
    ),
  ];
}
