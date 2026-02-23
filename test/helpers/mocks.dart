import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:mocktail/mocktail.dart';

export 'package:mocktail/mocktail.dart';
export 'core_mocks.dart';

class MockSettingsBloc extends Mock implements SettingsBloc {}

class MockAccountListBloc extends Mock implements AccountListBloc {}

class MockTransactionListBloc extends Mock implements TransactionListBloc {}

class MockBudgetListBloc extends Mock implements BudgetListBloc {}
