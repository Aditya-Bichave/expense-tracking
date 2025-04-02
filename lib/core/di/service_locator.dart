// lib/core/di/service_locator.dart
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Import SharedPreferences
import 'package:uuid/uuid.dart';

// Import Event
import 'package:expense_tracker/core/events/data_change_event.dart';

// Import Data Sources
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
// --- Settings Data Source Import ---
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart'; // Corrected typo: expense_tracking
// --- End Settings Data Source Import ---

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
// --- Settings Repository Import ---
import 'package:expense_tracker/features/settings/data/repositories/settings_repository_impl.dart'; // Corrected typo: expense_tracking
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart'; // Corrected typo: expense_tracking
// --- End Settings Repository Import ---

// Import Use Cases (Keep existing)
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
// --- Settings Use Cases (will be added later) ---

// Import Blocs (Keep existing)
import 'package:expense_tracker/features/expenses/presentation/bloc/add_edit_expense/add_edit_expense_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/add_edit_income/add_edit_income_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
// --- Settings Bloc Import ---
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Corrected typo: expense_tracking
// --- End Settings Bloc Import ---

// Import Entities (needed for factory params)
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';

final sl = GetIt.instance;

// Modify initLocator to accept dependencies needed during setup
Future<void> initLocator({
  required SharedPreferences prefs,
  required Box<ExpenseModel> expenseBox,
  required Box<AssetAccountModel> accountBox,
  required Box<IncomeModel> incomeBox,
}) async {
  // *** START: Data Change Event Stream ***
  // Register only if not already registered (optional check)
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

  // --- Feature Registrations ---

  _registerSettingsFeature(); // Register New Settings Feature
  _registerExpensesFeature();
  _registerAccountsFeature();
  _registerIncomeFeature();
  _registerAnalyticsAndDashboardFeatures();
}

// --- Registration Functions per Feature ---

void _registerSettingsFeature() {
  // Data sources
  sl.registerLazySingleton<SettingsLocalDataSource>(
      // Inject SharedPreferences instance registered above
      () => SettingsLocalDataSourceImpl(prefs: sl()));

  // Repositories
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(localDataSource: sl()));

  // Blocs
  // Register as LazySingleton because it holds state needed globally (theme)
  sl.registerLazySingleton(() => SettingsBloc(settingsRepository: sl()));

  // Settings Use Cases for Data Management (Register here later when created in Phase 4)
  // Example:
  // sl.registerLazySingleton(() => BackupDataUseCase(sl(), sl(), sl(), sl()));
  // sl.registerLazySingleton(() => RestoreDataUseCase(sl(), sl(), sl(), sl()));
  // sl.registerLazySingleton(() => ClearAllDataUseCase(sl(), sl(), sl()));
}

void _registerExpensesFeature() {
  // Data sources
  sl.registerLazySingleton<ExpenseLocalDataSource>(
    () => HiveExpenseLocalDataSource(
        sl<Box<ExpenseModel>>()), // Pass specific box
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
      // *** REMOVED dataChangeController parameter ***
    ),
  );
  sl.registerLazySingleton(() => ExpenseListBloc(
        getExpensesUseCase: sl(),
        deleteExpenseUseCase: sl(),
        dataChangeStream:
            sl<Stream<DataChangedEvent>>(), // Pass stream for listening
      ));
}

void _registerAccountsFeature() {
  // Data sources
  sl.registerLazySingleton<AssetAccountLocalDataSource>(
    () => HiveAssetAccountLocalDataSource(
        sl<Box<AssetAccountModel>>()), // Pass specific box
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
  sl.registerLazySingleton(
      () => DeleteAssetAccountUseCase(sl())); // Add dependencies if needed
  // Blocs
  sl.registerFactoryParam<AddEditAccountBloc, AssetAccount?, void>(
    (initialAccount, _) => AddEditAccountBloc(
      addAssetAccountUseCase: sl(),
      updateAssetAccountUseCase: sl(),
      initialAccount: initialAccount,
      // *** REMOVED dataChangeController parameter ***
    ),
  );
  sl.registerLazySingleton(() => AccountListBloc(
        getAssetAccountsUseCase: sl(),
        deleteAssetAccountUseCase: sl(),
        dataChangeStream:
            sl<Stream<DataChangedEvent>>(), // Pass stream for listening
      ));
}

void _registerIncomeFeature() {
  // Data sources
  sl.registerLazySingleton<IncomeLocalDataSource>(
    () =>
        HiveIncomeLocalDataSource(sl<Box<IncomeModel>>()), // Pass specific box
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
      // *** REMOVED dataChangeController parameter ***
    ),
  );
  sl.registerLazySingleton(() => IncomeListBloc(
        getIncomesUseCase: sl(),
        deleteIncomeUseCase: sl(),
        dataChangeStream:
            sl<Stream<DataChangedEvent>>(), // Pass stream for listening
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
        dataChangeStream:
            sl<Stream<DataChangedEvent>>(), // Pass stream for listening
      ));
  sl.registerLazySingleton(() => DashboardBloc(
        getFinancialOverviewUseCase: sl(),
        dataChangeStream:
            sl<Stream<DataChangedEvent>>(), // Pass stream for listening
      ));
}

// Helper function to publish data change events (Keep as is)
void publishDataChangedEvent(
    {required DataChangeType type, required DataChangeReason reason}) {
  try {
    // Retrieve the singleton StreamController and add the event
    sl<StreamController<DataChangedEvent>>()
        .add(DataChangedEvent(type: type, reason: reason));
    print("Published DataChangedEvent: Type=$type, Reason=$reason");
  } catch (e) {
    // Log error if the controller isn't registered or another issue occurs
    print("Error publishing DataChangedEvent: $e");
  }
}
