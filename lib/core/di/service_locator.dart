// lib/core/di/service_locator.dart
import 'dart:async'; // Import async
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

// Import Event
import 'package:expense_tracker/core/events/data_change_event.dart';

// Import Data Sources
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';

// Import Models (needed for Hive Box registration)
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';

// Import Repositories
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/accounts/data/repositories/asset_account_repository_impl.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

// Import Use Cases
// Expenses
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
// Accounts
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
// Income
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
// Analytics & Dashboard
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';

// Import Blocs
// Expenses
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
// Accounts
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
// Income
import 'package:expense_tracker/features/income/presentation/bloc/add_edit_income/add_edit_income_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
// Analytics & Dashboard
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// Import Entities (needed for factory params)
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

final sl = GetIt.instance;

Future<void> initLocator() async {
  // *** START: Data Change Event Stream ***
  // Use a broadcast stream so multiple Blocs can listen
  final dataChangeController = StreamController<DataChangedEvent>.broadcast();
  // Register the StreamController (to add events) and the Stream (to listen)
  sl.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController);
  sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);
  // *** END: Data Change Event Stream ***

  // External
  sl.registerLazySingleton(() => Uuid());
  // Hive Boxes (assuming they are opened in main.dart before calling initLocator)
  sl.registerLazySingleton<Box<ExpenseModel>>(
      () => Hive.box<ExpenseModel>('expenses'));
  sl.registerLazySingleton<Box<AssetAccountModel>>(
      () => Hive.box<AssetAccountModel>('asset_accounts'));
  sl.registerLazySingleton<Box<IncomeModel>>(
      () => Hive.box<IncomeModel>('incomes'));

  // Data sources
  sl.registerLazySingleton<ExpenseLocalDataSource>(
    () => HiveExpenseLocalDataSource(sl()),
  );
  sl.registerLazySingleton<AssetAccountLocalDataSource>(
    () => HiveAssetAccountLocalDataSource(sl()),
  );
  sl.registerLazySingleton<IncomeLocalDataSource>(
    () => HiveIncomeLocalDataSource(sl()),
  );

  // Repositories
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<IncomeRepository>(
    () => IncomeRepositoryImpl(localDataSource: sl()),
  );
  sl.registerLazySingleton<AssetAccountRepository>(
    () => AssetAccountRepositoryImpl(
      localDataSource: sl(),
      incomeRepository: sl(), // Depends on other repos
      expenseRepository: sl(),
    ),
  );

  // Use cases
  // Expenses
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  // Accounts
  sl.registerLazySingleton(() => AddAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetAssetAccountsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssetAccountUseCase(sl()));
  // Income
  sl.registerLazySingleton(() => AddIncomeUseCase(sl()));
  sl.registerLazySingleton(() => GetIncomesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateIncomeUseCase(sl()));
  sl.registerLazySingleton(() => DeleteIncomeUseCase(sl()));
  // Analytics & Dashboard
  sl.registerLazySingleton(() => GetExpenseSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetFinancialOverviewUseCase(
        accountRepository: sl(),
        incomeRepository: sl(),
        expenseRepository: sl(),
      ));

  // Blocs
  // Registering as Factory means a new instance is created each time requested
  // Use registerSingleton if you want the same instance everywhere (often preferred for list blocs)

  // Expenses
  sl.registerFactoryParam<AddEditExpenseBloc, Expense?, void>(
    (initialExpense, _) => AddEditExpenseBloc(
      addExpenseUseCase: sl(),
      updateExpenseUseCase: sl(),
      initialExpense: initialExpense,
    ),
  );
  sl.registerLazySingleton(() => ExpenseListBloc(
        getExpensesUseCase: sl(),
        deleteExpenseUseCase: sl(),
        // *** Subscribe to stream ***
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));

  // Accounts
  sl.registerFactoryParam<AddEditAccountBloc, AssetAccount?, void>(
    (initialAccount, _) => AddEditAccountBloc(
      addAssetAccountUseCase: sl(),
      updateAssetAccountUseCase: sl(),
      initialAccount: initialAccount,
    ),
  );
  sl.registerLazySingleton(() => AccountListBloc(
        getAssetAccountsUseCase: sl(),
        deleteAssetAccountUseCase: sl(),
        // *** Subscribe to stream ***
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));

  // Income
  sl.registerFactoryParam<AddEditIncomeBloc, Income?, void>(
    (initialIncome, _) => AddEditIncomeBloc(
      addIncomeUseCase: sl(),
      updateIncomeUseCase: sl(),
      initialIncome: initialIncome,
    ),
  );
  sl.registerLazySingleton(() => IncomeListBloc(
        getIncomesUseCase: sl(),
        deleteIncomeUseCase: sl(),
        // *** Subscribe to stream ***
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));

  // Analytics & Dashboard
  sl.registerLazySingleton(() => SummaryBloc(
        getExpenseSummaryUseCase: sl(),
        // *** Subscribe to stream ***
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
  sl.registerLazySingleton(() => DashboardBloc(
        getFinancialOverviewUseCase: sl(),
        // *** Subscribe to stream ***
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
}

// Helper function to publish data change events
void publishDataChangedEvent(
    {required DataChangeType type, required DataChangeReason reason}) {
  try {
    sl<StreamController<DataChangedEvent>>()
        .add(DataChangedEvent(type: type, reason: reason));
    print("Published DataChangedEvent: Type=$type, Reason=$reason");
  } catch (e) {
    print("Error publishing DataChangedEvent: $e");
    // Handle cases where the stream controller might not be registered yet
  }
}
