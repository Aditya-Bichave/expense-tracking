// lib/core/di/service_locator.dart
import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/main.dart'; // Logger
import 'package:expense_tracker/core/events/data_change_event.dart';

// --- Import Feature Dependency Initializers ---
import 'package:expense_tracker/core/di/service_configurations/settings_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/data_management_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/categories_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/accounts_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/income_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/expenses_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/transactions_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/dashboard_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/analytics_dependencies.dart';

// Import models only needed for Box types here
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';

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
        dataChangeController,
        instanceName: 'dataChangeController');
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);
    log.info("Registered DataChangedEvent StreamController and Stream.");
  }

  // *** Register Pre-initialized External Dependencies (LazySingleton) ***
  sl.registerLazySingleton<SharedPreferences>(() => prefs);
  sl.registerLazySingleton<Box<ExpenseModel>>(() => expenseBox);
  sl.registerLazySingleton<Box<AssetAccountModel>>(() => accountBox);
  sl.registerLazySingleton<Box<IncomeModel>>(() => incomeBox);
  sl.registerLazySingleton<Box<CategoryModel>>(() => categoryBox);
  sl.registerLazySingleton<Box<UserHistoryRuleModel>>(() => userHistoryBox);
  log.info("Registered SharedPreferences and Hive Boxes.");

  // *** Other External Dependencies (LazySingleton) ***
  sl.registerLazySingleton(() => const Uuid());
  log.info("Registered Uuid generator.");

  // *** Call Feature Dependency Initializers ***
  // Order matters: Register foundational repos/datasources first if others depend on them.
  log.info("Registering feature dependencies...");
  SettingsDependencies.register();
  DataManagementDependencies.register();
  IncomeDependencies.register(); // Income Repo needed by Accounts, Transactions
  ExpensesDependencies
      .register(); // Expense Repo needed by Accounts, Transactions
  CategoriesDependencies
      .register(); // Category Repo needed by Transactions, Add/Edit Txn
  AccountDependencies.register(); // Account Repo needed by Dashboard
  TransactionsDependencies.register(); // Transaction UseCases/Blocs
  DashboardDependencies.register();
  AnalyticsDependencies.register();

  log.info("Service Locator initialization complete.");
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
      log.severe("Error publishing DataChangedEvent: $e\n$s");
    }
  } else {
    log.warning(
        "Attempted to publish DataChangedEvent, but StreamController is not registered.");
  }
}
