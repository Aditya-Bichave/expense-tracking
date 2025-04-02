// lib/core/di/service_locator.dart
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/main.dart'; // Import logger

// Import Event
import 'package:expense_tracker/core/events/data_change_event.dart';

// Import Data Sources
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';

// Import Models (needed for Hive Box types)
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
import 'package:expense_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/data/repositories/data_management_repository_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';

// Import Use Cases
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';

// Import Blocs
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/add_edit_income/add_edit_income_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

// Import Entities
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

final sl = GetIt.instance;

Future<void> initLocator({
  required SharedPreferences prefs,
  required Box<ExpenseModel> expenseBox,
  required Box<AssetAccountModel> accountBox,
  required Box<IncomeModel> incomeBox,
}) async {
  log.info("Initializing Service Locator...");

  // *** START: Data Change Event Stream ***
  if (!sl.isRegistered<StreamController<DataChangedEvent>>()) {
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    sl.registerSingleton<StreamController<DataChangedEvent>>(
        dataChangeController);
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);
    log.info("Registered DataChangedEvent StreamController and Stream.");
  }
  // *** END: Data Change Event Stream ***

  // Register Pre-initialized External Dependencies
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Box<ExpenseModel>>(() => expenseBox);
  sl.registerLazySingleton<Box<AssetAccountModel>>(() => accountBox);
  sl.registerLazySingleton<Box<IncomeModel>>(() => incomeBox);
  log.info("Registered SharedPreferences and Hive Boxes.");

  // Other External Dependencies
  sl.registerLazySingleton(() => const Uuid());
  log.info("Registered Uuid generator.");

  // --- Feature Registrations ---
  _registerSettingsFeature();
  _registerExpensesFeature();
  _registerAccountsFeature();
  _registerIncomeFeature();
  _registerAnalyticsAndDashboardFeatures();

  log.info("Service Locator initialization complete.");
}

void _registerSettingsFeature() {
  log.info("Registering Settings Feature dependencies...");
  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(prefs: sl()));

  // Repositories
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(localDataSource: sl()));

  // --- Register Data Management Repository ---
  sl.registerLazySingleton<DataManagementRepository>(() =>
      DataManagementRepositoryImpl(
          accountBox: sl(), expenseBox: sl(), incomeBox: sl()));
  // -----------------------------------------

  // --- Register Data Management Use Cases ---
  sl.registerLazySingleton(() => BackupDataUseCase(sl()));
  sl.registerLazySingleton(() => RestoreDataUseCase(sl()));
  sl.registerLazySingleton(() => ClearAllDataUseCase(sl()));
  // ------------------------------------------

  // Blocs
  sl.registerLazySingleton(() => SettingsBloc(
        settingsRepository: sl(),
        backupDataUseCase: sl(),
        restoreDataUseCase: sl(),
        clearAllDataUseCase: sl(),
      ));
  log.info("Settings Feature dependencies registered.");
}

void _registerExpensesFeature() {
  log.info("Registering Expenses Feature dependencies...");
  // Data sources
  sl.registerLazySingleton<ExpenseLocalDataSource>(
    () => HiveExpenseLocalDataSource(sl<Box<ExpenseModel>>()),
  );
  // Repositories
  sl.registerLazySingleton<ExpenseRepository>(
    () => ExpenseRepositoryImpl(localDataSource: sl()),
  );
  // Use cases
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  sl.registerLazySingleton(() => GetExpensesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  // Blocs
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
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
  log.info("Expenses Feature dependencies registered.");
}

void _registerAccountsFeature() {
  log.info("Registering Accounts Feature dependencies...");
  // Data sources
  sl.registerLazySingleton<AssetAccountLocalDataSource>(
    () => HiveAssetAccountLocalDataSource(sl<Box<AssetAccountModel>>()),
  );
  // Repositories
  sl.registerLazySingleton<AssetAccountRepository>(
    () => AssetAccountRepositoryImpl(
      localDataSource: sl(),
      incomeRepository: sl(), // Needs Income/Expense repo for balance calc
      expenseRepository: sl(),
    ),
  );
  // Use cases
  sl.registerLazySingleton(() => AddAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetAssetAccountsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssetAccountUseCase(sl()));
  // Blocs
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
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
  log.info("Accounts Feature dependencies registered.");
}

void _registerIncomeFeature() {
  log.info("Registering Income Feature dependencies...");
  // Data sources
  sl.registerLazySingleton<IncomeLocalDataSource>(
    () => HiveIncomeLocalDataSource(sl<Box<IncomeModel>>()),
  );
  // Repositories
  sl.registerLazySingleton<IncomeRepository>(
    () => IncomeRepositoryImpl(localDataSource: sl()),
  );
  // Use cases
  sl.registerLazySingleton(() => AddIncomeUseCase(sl()));
  sl.registerLazySingleton(() => GetIncomesUseCase(sl()));
  sl.registerLazySingleton(() => UpdateIncomeUseCase(sl()));
  sl.registerLazySingleton(() => DeleteIncomeUseCase(sl()));
  // Blocs
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
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
  log.info("Income Feature dependencies registered.");
}

void _registerAnalyticsAndDashboardFeatures() {
  log.info("Registering Analytics & Dashboard Features dependencies...");
  // Use cases
  sl.registerLazySingleton(() => GetExpenseSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetFinancialOverviewUseCase(
        accountRepository: sl(),
        incomeRepository: sl(),
        expenseRepository: sl(),
      ));
  // Blocs
  sl.registerLazySingleton(() => SummaryBloc(
        getExpenseSummaryUseCase: sl(),
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
  sl.registerLazySingleton(() => DashboardBloc(
        getFinancialOverviewUseCase: sl(),
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
  log.info("Analytics & Dashboard Features dependencies registered.");
}

// Helper function to publish data change events
void publishDataChangedEvent(
    {required DataChangeType type, required DataChangeReason reason}) {
  if (sl.isRegistered<StreamController<DataChangedEvent>>()) {
    try {
      sl<StreamController<DataChangedEvent>>()
          .add(DataChangedEvent(type: type, reason: reason));
      log.info("Published DataChangedEvent: Type=$type, Reason=$reason");
    } catch (e, s) {
      log.severe("Error publishing DataChangedEvent$e$s");
    }
  } else {
    log.warning(
        "Attempted to publish DataChangedEvent, but StreamController is not registered.");
  }
}
