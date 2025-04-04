import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/main.dart'; // Import logger

// Import Event
import 'package:expense_tracker/core/events/data_change_event.dart';

// --- Data Sources ---
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/user_history_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/merchant_category_data_source.dart';

// --- Models (needed for Hive Box types) ---
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';

// --- Repositories (Interfaces) ---
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/asset_account_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';

// --- Repositories (Implementations) ---
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/accounts/data/repositories/asset_account_repository_impl.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:expense_tracker/features/settings/data/repositories/data_management_repository_impl.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart'; // Direct import ok here
import 'package:expense_tracker/features/categories/data/repositories/user_history_repository_impl.dart';
import 'package:expense_tracker/features/categories/data/repositories/merchant_category_repository_impl.dart';

// --- Use Cases ---
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
// import 'package:expense_tracker/features/expenses/domain/usecases/get_expenses.dart'; // Likely Obsolete
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/add_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/delete_asset_account.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/update_asset_account.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
// import 'package:expense_tracker/features/income/domain/usecases/get_incomes.dart'; // Likely Obsolete
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_expense_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_income_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/settings/domain/usecases/backup_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/restore_data_usecase.dart';
import 'package:expense_tracker/features/settings/domain/usecases/clear_all_data_usecase.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart'; // Unified List Usecase

// --- Blocs ---
import 'package:expense_tracker/features/accounts/presentation/bloc/add_edit_account/add_edit_account_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';

// Import Entities needed for factory parameters
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

final sl = GetIt.instance;

Future<void> initLocator({
  required SharedPreferences prefs,
  required Box<ExpenseModel> expenseBox,
  required Box<AssetAccountModel> accountBox,
  required Box<IncomeModel> incomeBox,
  required Box<CategoryModel> categoryBox,
  required Box<UserHistoryRuleModel> userHistoryBox,
}) async {
  log.info("Initializing Service Locator...");

  // *** Data Change Event Stream ***
  if (!sl.isRegistered<StreamController<DataChangedEvent>>()) {
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    sl.registerSingleton<StreamController<DataChangedEvent>>(
        dataChangeController);
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);
    log.info("Registered DataChangedEvent StreamController and Stream.");
  }

  // *** Register Pre-initialized External Dependencies ***
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Box<ExpenseModel>>(() => expenseBox);
  sl.registerLazySingleton<Box<AssetAccountModel>>(() => accountBox);
  sl.registerLazySingleton<Box<IncomeModel>>(() => incomeBox);
  sl.registerLazySingleton<Box<CategoryModel>>(() => categoryBox);
  sl.registerLazySingleton<Box<UserHistoryRuleModel>>(() => userHistoryBox);
  log.info("Registered SharedPreferences and Hive Boxes.");

  // *** Other External Dependencies ***
  sl.registerLazySingleton(() => const Uuid());
  log.info("Registered Uuid generator.");

  // *** Feature Registrations (Order Matters for Dependencies) ***
  _registerSettingsFeature();
  _registerIncomeFeature(); // Register repos first
  _registerExpensesFeature(); // Register repos first
  _registerCategoryFeature(); // Register repos first
  _registerAccountsFeature(); // Register repos first
  _registerTransactionsFeature(); // Register GetTransactionsUseCase and List Bloc
  _registerAddEditTransactionFeature(); // Register Add/Edit Bloc
  _registerAnalyticsAndDashboardFeatures(); // Register remaining use cases and Blocs

  log.info("Service Locator initialization complete.");
}

// ==================== Feature Registration Functions ====================

void _registerSettingsFeature() {
  log.info("Registering Settings Feature dependencies...");
  sl.registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(prefs: sl()));
  sl.registerLazySingleton<DataManagementRepository>(() =>
      DataManagementRepositoryImpl(
          accountBox: sl(), expenseBox: sl(), incomeBox: sl()));
  sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton(() => BackupDataUseCase(sl()));
  sl.registerLazySingleton(() => RestoreDataUseCase(sl()));
  sl.registerLazySingleton(() => ClearAllDataUseCase(sl()));
  sl.registerFactory(() => SettingsBloc(
      settingsRepository: sl(),
      backupDataUseCase: sl(),
      restoreDataUseCase: sl(),
      clearAllDataUseCase: sl()));
  log.info("Settings Feature dependencies registered.");
}

void _registerCategoryFeature() {
  log.info("Registering Category Feature dependencies...");
  // Data Sources
  sl.registerLazySingleton<CategoryLocalDataSource>(
      () => HiveCategoryLocalDataSource(sl()));
  sl.registerLazySingleton<CategoryPredefinedDataSource>(
      () => AssetExpenseCategoryDataSource(),
      instanceName: 'expensePredefined');
  sl.registerLazySingleton<CategoryPredefinedDataSource>(
      () => AssetIncomeCategoryDataSource(),
      instanceName: 'incomePredefined');
  sl.registerLazySingleton<UserHistoryLocalDataSource>(
      () => HiveUserHistoryLocalDataSource(sl()));
  sl.registerLazySingleton<MerchantCategoryDataSource>(
      () => AssetMerchantCategoryDataSource());
  // Repository
  sl.registerLazySingleton<CategoryRepository>(() {
    final CategoryRepositoryImpl impl = CategoryRepositoryImpl(
      localDataSource: sl<CategoryLocalDataSource>(),
      expensePredefinedDataSource:
          sl<CategoryPredefinedDataSource>(instanceName: 'expensePredefined'),
      incomePredefinedDataSource:
          sl<CategoryPredefinedDataSource>(instanceName: 'incomePredefined'),
    );
    return impl;
  });
  sl.registerLazySingleton<UserHistoryRepository>(
      () => UserHistoryRepositoryImpl(localDataSource: sl()));
  sl.registerLazySingleton<MerchantCategoryRepository>(
      () => MerchantCategoryRepositoryImpl(dataSource: sl()));
  // Use Cases
  sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetExpenseCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => GetIncomeCategoriesUseCase(sl()));
  sl.registerLazySingleton(() => AddCustomCategoryUseCase(sl(), sl()));
  sl.registerLazySingleton(() => UpdateCustomCategoryUseCase(sl()));
  sl.registerLazySingleton(() => DeleteCustomCategoryUseCase(sl(), sl(), sl()));
  sl.registerLazySingleton(
      () => SaveUserCategorizationHistoryUseCase(sl(), sl()));
  sl.registerLazySingleton(() => CategorizeTransactionUseCase(
      userHistoryRepository: sl(),
      merchantCategoryRepository: sl(),
      categoryRepository: sl()));
  sl.registerLazySingleton(() => ApplyCategoryToBatchUseCase(
      expenseRepository: sl(), incomeRepository: sl()));
  // Presentation
  sl.registerFactory(() => CategoryManagementBloc(
      getCategoriesUseCase: sl(),
      addCustomCategoryUseCase: sl(),
      updateCustomCategoryUseCase: sl(),
      deleteCustomCategoryUseCase: sl()));
  log.info("Category Feature dependencies registered.");
}

void _registerAccountsFeature() {
  log.info("Registering Accounts Feature dependencies...");
  // Data
  sl.registerLazySingleton<AssetAccountLocalDataSource>(
      () => HiveAssetAccountLocalDataSource(sl<Box<AssetAccountModel>>()));
  sl.registerLazySingleton<AssetAccountRepository>(() =>
      AssetAccountRepositoryImpl(
          localDataSource: sl(),
          incomeRepository: sl<IncomeRepository>(),
          expenseRepository: sl<ExpenseRepository>()));
  // Domain
  sl.registerLazySingleton(() => AddAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => GetAssetAccountsUseCase(sl()));
  sl.registerLazySingleton(() => UpdateAssetAccountUseCase(sl()));
  sl.registerLazySingleton(() => DeleteAssetAccountUseCase(sl()));
  // Presentation
  sl.registerFactoryParam<AddEditAccountBloc, AssetAccount?, void>(
      (initialAccount, _) => AddEditAccountBloc(
          addAssetAccountUseCase: sl(),
          updateAssetAccountUseCase: sl(),
          initialAccount: initialAccount));
  sl.registerFactory(() => AccountListBloc(
      getAssetAccountsUseCase: sl(),
      deleteAssetAccountUseCase: sl(),
      dataChangeStream: sl<Stream<DataChangedEvent>>()));
  log.info("Accounts Feature dependencies registered.");
}

void _registerIncomeFeature() {
  log.info("Registering Income Feature dependencies...");
  // Data
  sl.registerLazySingleton<IncomeLocalDataSource>(
      () => HiveIncomeLocalDataSource(sl<Box<IncomeModel>>()));
  sl.registerLazySingleton<IncomeRepository>(
      () => IncomeRepositoryImpl(localDataSource: sl()));
  // Domain
  sl.registerLazySingleton(() => AddIncomeUseCase(sl()));
  // sl.registerLazySingleton(() => GetIncomesUseCase(sl())); // Removed - Superseded by GetTransactionsUseCase
  sl.registerLazySingleton(() => UpdateIncomeUseCase(sl()));
  sl.registerLazySingleton(() => DeleteIncomeUseCase(sl()));
  log.info("Income Feature dependencies registered.");
}

void _registerExpensesFeature() {
  log.info("Registering Expenses Feature dependencies...");
  // Data
  sl.registerLazySingleton<ExpenseLocalDataSource>(
      () => HiveExpenseLocalDataSource(sl<Box<ExpenseModel>>()));
  sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(localDataSource: sl()));
  // Domain
  sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
  // sl.registerLazySingleton(() => GetExpensesUseCase(sl())); // Removed - Superseded by GetTransactionsUseCase
  sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
  sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  log.info("Expenses Feature dependencies registered.");
}

void _registerTransactionsFeature() {
  log.info("Registering Transactions Feature (List/Hydration) dependencies...");
  // --- Domain Layer ---
  // GetTransactionsUseCase now handles hydration
  sl.registerLazySingleton(() => GetTransactionsUseCase(
        expenseRepository: sl(),
        incomeRepository: sl(),
        categoryRepository: sl(), // Inject Category Repo for hydration
      ));
  // Delete use cases are already registered

  // --- Presentation Layer (List Bloc) ---
  sl.registerFactory(() => TransactionListBloc(
        getTransactionsUseCase: sl(), // This now returns hydrated list
        deleteExpenseUseCase: sl(),
        deleteIncomeUseCase: sl(),
        applyCategoryToBatchUseCase: sl(),
        saveUserHistoryUseCase: sl(),
        expenseRepository: sl(),
        incomeRepository: sl(),
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ));
  log.info("Transactions Feature (List/Hydration) dependencies registered.");
}

void _registerAddEditTransactionFeature() {
  log.info("Registering Add/Edit Transaction Feature dependencies...");
  // Register the new unified Bloc, injecting all necessary dependencies
  sl.registerFactory<AddEditTransactionBloc>(() => AddEditTransactionBloc(
        addExpenseUseCase: sl(), updateExpenseUseCase: sl(),
        addIncomeUseCase: sl(), updateIncomeUseCase: sl(),
        categorizeTransactionUseCase: sl(),
        expenseRepository: sl(), incomeRepository: sl(),
        categoryRepository: sl(), // Inject CategoryRepository interface
      ));
  log.info("Add/Edit Transaction Feature dependencies registered.");
}

void _registerAnalyticsAndDashboardFeatures() {
  log.info("Registering Analytics & Dashboard Features dependencies...");
  // Domain
  sl.registerLazySingleton(() => GetExpenseSummaryUseCase(sl()));
  sl.registerLazySingleton(() => GetFinancialOverviewUseCase(
      accountRepository: sl(),
      incomeRepository: sl(),
      expenseRepository: sl()));
  // Presentation
  sl.registerFactory(() => SummaryBloc(
      getExpenseSummaryUseCase: sl(),
      dataChangeStream: sl<Stream<DataChangedEvent>>()));
  sl.registerFactory(() => DashboardBloc(
      getFinancialOverviewUseCase: sl(),
      dataChangeStream: sl<Stream<DataChangedEvent>>()));
  log.info("Analytics & Dashboard Features dependencies registered.");
}

// --- Keep publishDataChangedEvent ---
void publishDataChangedEvent(
    {required DataChangeType type, required DataChangeReason reason}) {
  if (sl.isRegistered<StreamController<DataChangedEvent>>()) {
    try {
      sl<StreamController<DataChangedEvent>>()
          .add(DataChangedEvent(type: type, reason: reason));
      log.fine("Published DataChangedEvent: Type=$type, Reason=$reason");
    } catch (e, s) {
      log.severe("Error publishing DataChangedEvent$e$s");
    }
  } else {
    log.warning(
        "Attempted to publish DataChangedEvent, but StreamController is not registered.");
  }
}
