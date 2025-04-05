// lib/core/di/service_locator.dart
import 'dart:async';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/main.dart'; // Logger
import 'package:expense_tracker/core/events/data_change_event.dart';

// --- Import Feature Dependency Configuration Files ---
import 'package:expense_tracker/core/di/service_configurations/settings_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/data_management_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/categories_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/accounts_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/income_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/expenses_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/transactions_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/dashboard_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/analytics_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/budget_dependencies.dart'; // Correct single import
import 'package:expense_tracker/core/di/service_configurations/goal_dependencies.dart';

// Import models only needed for Box types here
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';

final sl = GetIt.instance;

Future<void> initLocator({
  required SharedPreferences prefs,
  required Box<ExpenseModel> expenseBox,
  required Box<AssetAccountModel> accountBox,
  required Box<IncomeModel> incomeBox,
  required Box<CategoryModel> categoryBox,
  required Box<UserHistoryRuleModel> userHistoryBox,
  required Box<BudgetModel> budgetBox,
  required Box<GoalModel> goalBox,
  required Box<GoalContributionModel> contributionBox,
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
  } else {
    log.warning(
        "DataChangedEvent StreamController already registered."); // Add warning
  }

  // *** Register Pre-initialized External Dependencies (LazySingleton) ***
  // Use isRegistered check for safety during hot restarts potentially
  if (!sl.isRegistered<SharedPreferences>())
    sl.registerLazySingleton<SharedPreferences>(() => prefs);
  if (!sl.isRegistered<Box<ExpenseModel>>())
    sl.registerLazySingleton<Box<ExpenseModel>>(() => expenseBox);
  if (!sl.isRegistered<Box<AssetAccountModel>>())
    sl.registerLazySingleton<Box<AssetAccountModel>>(() => accountBox);
  if (!sl.isRegistered<Box<IncomeModel>>())
    sl.registerLazySingleton<Box<IncomeModel>>(() => incomeBox);
  if (!sl.isRegistered<Box<CategoryModel>>())
    sl.registerLazySingleton<Box<CategoryModel>>(() => categoryBox);
  if (!sl.isRegistered<Box<UserHistoryRuleModel>>())
    sl.registerLazySingleton<Box<UserHistoryRuleModel>>(() => userHistoryBox);
  if (!sl.isRegistered<Box<BudgetModel>>())
    sl.registerLazySingleton<Box<BudgetModel>>(() => budgetBox);
  if (!sl.isRegistered<Box<GoalModel>>())
    sl.registerLazySingleton<Box<GoalModel>>(() => goalBox);
  if (!sl.isRegistered<Box<GoalContributionModel>>())
    sl.registerLazySingleton<Box<GoalContributionModel>>(() => contributionBox);
  log.info(
      "Registered SharedPreferences and Hive Boxes (incl. Budgets, Goals, Contributions).");

  // *** Other External Dependencies (LazySingleton) ***
  if (!sl.isRegistered<Uuid>())
    sl.registerLazySingleton(() => const Uuid()); // Check if registered
  log.info("Registered Uuid generator.");

  // *** Call Feature Dependency Initializers (Call ONLY ONCE) ***
  log.info("Registering feature dependencies...");
  // Wrap in a check to prevent re-registration during hot restart if initLocator is called again
  // This is a basic safeguard, proper DI setup usually handles this better.
  if (!sl.isRegistered<SettingsRepository>()) {
    // Use a core repo as a check flag
    SettingsDependencies.register();
    DataManagementDependencies.register();
    IncomeDependencies.register();
    ExpensesDependencies.register();
    CategoriesDependencies.register();
    AccountDependencies.register();
    BudgetDependencies.register(); // <<< Called only ONCE here
    GoalDependencies.register();
    TransactionsDependencies.register();
    DashboardDependencies.register();
    AnalyticsDependencies.register();
    log.info("Feature dependencies registered.");
  } else {
    log.warning(
        "Feature dependencies seem to be already registered. Skipping registration call.");
  }

  log.info("Service Locator initialization complete.");
}

// --- publishDataChangedEvent ---
void publishDataChangedEvent(
    {required DataChangeType type, required DataChangeReason reason}) {
  // ... (implementation as before) ...
  if (sl.isRegistered<StreamController<DataChangedEvent>>(
      instanceName: 'dataChangeController')) {
    // Check with instance name
    try {
      sl<StreamController<DataChangedEvent>>(
              instanceName: 'dataChangeController')
          .add(DataChangedEvent(type: type, reason: reason));
      log.fine("Published DataChangedEvent: Type=$type, Reason=$reason");
    } catch (e, s) {
      log.severe("Error publishing DataChangedEvent: $e\n$s");
    }
  } else {
    log.warning(
        "Attempted to publish DataChangedEvent, but StreamController 'dataChangeController' is not registered.");
  }
}
