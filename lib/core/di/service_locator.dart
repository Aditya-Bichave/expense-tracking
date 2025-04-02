// lib/core/di/service_locator.dart
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:package_info_plus/package_info_plus.dart'; // Import PackageInfo

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
// --- Import Data Management Repository ---
import 'package:expense_tracker/features/settings/data/repositories/data_management_repository_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
// -----------------------------------------

// Import Use Cases
// (Keep existing expense, account, income, analytics, dashboard use cases)
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
// --- Import Data Management Use Cases ---
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
// ----------------------------------------

// Import Blocs
// (Keep existing expense, account, income, analytics, dashboard blocs)
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
// (Keep existing expense, account, income entities)
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
  // --- Existing Registrations (Stream, Externals, Features...) ---
  // *** START: Data Change Event Stream ***
  if (!sl.isRegistered<StreamController<DataChangedEvent>>()) {
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    sl.registerSingleton<StreamController<DataChangedEvent>>(
        dataChangeController);
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);
  }
  // *** END: Data Change Event Stream ***

  // Register Pre-initialized External Dependencies
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Box<ExpenseModel>>(() => expenseBox);
  sl.registerLazySingleton<Box<AssetAccountModel>>(() => accountBox);
  sl.registerLazySingleton<Box<IncomeModel>>(() => incomeBox);

  // Other External Dependencies
  sl.registerLazySingleton(() => Uuid());
  // Register PackageInfo Plus instance - used by Backup UseCase
  // Can be lazy singleton as it's fetched on demand
  // sl.registerLazySingletonAsync<PackageInfo>(() => PackageInfo.fromPlatform());
  // No need to register PackageInfo, use case can call fromPlatform directly.

  // --- Feature Registrations ---
  _registerSettingsFeature(); // Updated below
  _registerExpensesFeature();
  _registerAccountsFeature();
  _registerIncomeFeature();
  _registerAnalyticsAndDashboardFeatures();
}

void _registerSettingsFeature() {
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
  // Inject all required use cases into SettingsBloc
  sl.registerLazySingleton(() => SettingsBloc(
        settingsRepository: sl(),
        backupDataUseCase: sl(),
        restoreDataUseCase: sl(),
        clearAllDataUseCase: sl(),
      ));
}

// --- Keep other registration functions (_registerExpensesFeature, etc.) as they were ---
void _registerExpensesFeature() {
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
}

void _registerAccountsFeature() {
  // Data sources
  sl.registerLazySingleton<AssetAccountLocalDataSource>(
    () => HiveAssetAccountLocalDataSource(sl<Box<AssetAccountModel>>()),
  );
  // Repositories
  sl.registerLazySingleton<AssetAccountRepository>(
    () => AssetAccountRepositoryImpl(
      localDataSource: sl(),
      incomeRepository: sl(),
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
}

void _registerIncomeFeature() {
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
}

void _registerAnalyticsAndDashboardFeatures() {
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
}

// Helper function (Keep as is)
void publishDataChangedEvent(
    {required DataChangeType type, required DataChangeReason reason}) {
  try {
    sl<StreamController<DataChangedEvent>>()
        .add(DataChangedEvent(type: type, reason: reason));
    print("Published DataChangedEvent: Type=$type, Reason=$reason");
  } catch (e) {
    print("Error publishing DataChangedEvent: $e");
  }
}
