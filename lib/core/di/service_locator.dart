import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart'; // Needed for AddEdit Blocs if generating IDs there

// Core
import 'package:expense_tracker/core/usecases/usecase.dart'; // For NoParams

// Expense Feature: Data
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
// Expense Feature: Domain
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart'; // For AddEdit Bloc param
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
// Expense Feature: Presentation
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';

// Income Feature: Data
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
// Income Feature: Domain
import 'package:expense_tracker/features/income/domain/entities/income.dart'; // For AddEdit Bloc param
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
// Income Feature: Presentation
import 'package:expense_tracker/features/income/presentation/bloc/add_edit_income/add_edit_income_bloc.dart'; // Create these files
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart'; // Create these files

// Accounts Feature: Data
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/data/repositories/asset_account_repository_impl.dart';
// Accounts Feature: Domain
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart'; // For AddEdit Bloc param
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
// Accounts Feature: Presentation
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart'; // Create these files
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart'; // Create these files

// Analytics / Summary (Old - kept for specific expense summary)
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';

// Dashboard Feature
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart'; // Create these files

final sl = GetIt.instance; // sl = service locator

Future<void> initDI() async {
  // --- External (Hive) ---
  // Open boxes - do this before registering components that depend on them
  // Ensure Adapters are registered in main.dart *before* calling initDI
  final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
  final incomeBox = await Hive.openBox<IncomeModel>('incomes');
  final accountBox = await Hive.openBox<AssetAccountModel>('accounts');

  sl.registerSingleton<Box<ExpenseModel>>(expenseBox);
  sl.registerSingleton<Box<IncomeModel>>(incomeBox);
  sl.registerSingleton<Box<AssetAccountModel>>(accountBox);

  // --- Core ---
  sl.registerLazySingleton(
      () => const Uuid()); // For generating IDs if needed in Blocs/UseCases
  // Register NoParams if not already implicitly available via UseCase base class
  // sl.registerLazySingleton(() => NoParams()); // Usually not needed to register explicitly

  // --- Features ---

  // ** Repositories & Data Sources **
  // Register repositories that others depend on first (or ensure lazy loading handles order)

  // Expense
  sl.registerLazySingleton<ExpenseLocalDataSource>(
      () => HiveExpenseLocalDataSource(sl()));
  sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(localDataSource: sl()));

  // Income
  sl.registerLazySingleton<IncomeLocalDataSource>(
      () => HiveIncomeLocalDataSource(sl()));
  sl.registerLazySingleton<IncomeRepository>(
      () => IncomeRepositoryImpl(localDataSource: sl()));

  // Accounts (Depends on Income & Expense Repositories)
  sl.registerLazySingleton<AssetAccountLocalDataSource>(
      () => HiveAssetAccountLocalDataSource(sl()));
  sl.registerLazySingleton<AssetAccountRepository>(
      () => AssetAccountRepositoryImpl(
          localDataSource: sl(),
          incomeRepository: sl(), // Depends on IncomeRepository
          expenseRepository: sl() // Depends on ExpenseRepository
          ));

  // ** Use Cases **

  // Dashboard
  sl.registerLazySingleton(() => GetFinancialOverviewUseCase(
      accountRepository: sl(),
      incomeRepository: sl(),
      expenseRepository: sl()));

  // Expense
  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  sl.registerLazySingleton(
      () => GetExpenseSummaryUseCase(sl())); // Keep for specific summary

  // Income
  sl.registerLazySingleton(() => GetIncomesUseCase(sl()));
  sl.registerLazySingleton(() => AddIncomeUseCase(sl()));
  sl.registerLazySingleton(() => UpdateIncomeUseCase(sl()));
  sl.registerLazySingleton(() => DeleteIncomeUseCase(sl()));

  // Accounts
  sl.registerLazySingleton(() => GetAssetAccountsUseCase(sl()));
  sl.registerLazySingleton(() => AddAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssetAccountUseCase(sl()));

  // ** Blocs ** (Typically register as Factory)

  // Dashboard
  sl.registerFactory(() => DashboardBloc(getFinancialOverviewUseCase: sl()));

  // Expense
  sl.registerFactory(() =>
      ExpenseListBloc(getExpensesUseCase: sl(), deleteExpenseUseCase: sl()));
  // Use registerFactoryParam if AddEditExpenseBloc needs initialExpense passed during creation
  sl.registerFactoryParam<AddEditExpenseBloc, Expense?, void>(
      (initialExpense, _) => AddEditExpenseBloc(
          addExpenseUseCase: sl(),
          updateExpenseUseCase: sl(),
          initialExpense: initialExpense));

  // Income
  sl.registerFactory(
      () => IncomeListBloc(getIncomesUseCase: sl(), deleteIncomeUseCase: sl()));
  sl.registerFactoryParam<AddEditIncomeBloc, Income?, void>(
      (initialIncome, _) => AddEditIncomeBloc(
          addIncomeUseCase: sl(),
          updateIncomeUseCase: sl(),
          initialIncome: initialIncome));

  // Accounts
  sl.registerFactory(() => AccountListBloc(
      getAssetAccountsUseCase: sl(), deleteAssetAccountUseCase: sl()));
  sl.registerFactoryParam<AddEditAccountBloc, AssetAccount?, void>(
      (initialAccount, _) => AddEditAccountBloc(
          addAssetAccountUseCase: sl(),
          updateAssetAccountUseCase: sl(),
          initialAccount: initialAccount));

  // Analytics (Old Summary Bloc)
  // Keep if the specific expense summary page/widget is still used
  sl.registerFactory(() => SummaryBloc(getExpenseSummaryUseCase: sl()));
}
