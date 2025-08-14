// lib/core/di/service_locator.dart
import 'dart:async';
import 'package:expense_tracker/core/services/demo_mode_service.dart'; // Added
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
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
import 'package:expense_tracker/core/di/service_configurations/budget_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/goal_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/recurring_transactions_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/report_dependencies.dart';
import 'package:expense_tracker/core/services/downloader_service_locator.dart';
import 'package:expense_tracker/core/services/clock.dart';

// Import models only needed for Box types here
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';

// --- MODIFIED: Import Hive DataSources ---
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';
// --- END MODIFIED ---

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
  required Box<RecurringRuleModel> recurringRuleBox,
  required Box<RecurringRuleAuditLogModel> recurringRuleAuditLogBox,
}) async {
  log.info("Initializing Service Locator...");

  // *** Register Demo Mode Service (Singleton) ***
  if (!sl.isRegistered<DemoModeService>()) {
    sl.registerLazySingleton<DemoModeService>(() => DemoModeService());
    log.info("Registered DemoModeService.");
  }

  // *** Register Clock Service ***
  if (!sl.isRegistered<Clock>()) {
    sl.registerLazySingleton<Clock>(() => SystemClock());
  }

  // *** Data Change Event Stream ***
  if (!sl.isRegistered<StreamController<DataChangedEvent>>()) {
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    sl.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);
    log.info("Registered DataChangedEvent StreamController and Stream.");
  } else {
    log.warning("DataChangedEvent StreamController already registered.");
  }

  // *** Register Pre-initialized External Dependencies (LazySingleton) ***
  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerLazySingleton<SharedPreferences>(() => prefs);
  }
  if (!sl.isRegistered<Box<ExpenseModel>>()) {
    sl.registerLazySingleton<Box<ExpenseModel>>(() => expenseBox);
  }
  if (!sl.isRegistered<Box<AssetAccountModel>>()) {
    sl.registerLazySingleton<Box<AssetAccountModel>>(() => accountBox);
  }
  if (!sl.isRegistered<Box<IncomeModel>>()) {
    sl.registerLazySingleton<Box<IncomeModel>>(() => incomeBox);
  }
  if (!sl.isRegistered<Box<CategoryModel>>()) {
    sl.registerLazySingleton<Box<CategoryModel>>(() => categoryBox);
  }
  if (!sl.isRegistered<Box<UserHistoryRuleModel>>()) {
    sl.registerLazySingleton<Box<UserHistoryRuleModel>>(() => userHistoryBox);
  }
  if (!sl.isRegistered<Box<BudgetModel>>()) {
    sl.registerLazySingleton<Box<BudgetModel>>(() => budgetBox);
  }
  if (!sl.isRegistered<Box<GoalModel>>()) {
    sl.registerLazySingleton<Box<GoalModel>>(() => goalBox);
  }
  if (!sl.isRegistered<Box<GoalContributionModel>>()) {
    sl.registerLazySingleton<Box<GoalContributionModel>>(() => contributionBox);
  }
  if (!sl.isRegistered<Box<RecurringRuleModel>>()) {
    sl.registerLazySingleton<Box<RecurringRuleModel>>(() => recurringRuleBox);
  }
  if (!sl.isRegistered<Box<RecurringRuleAuditLogModel>>()) {
    sl.registerLazySingleton<Box<RecurringRuleAuditLogModel>>(
      () => recurringRuleAuditLogBox,
    );
  }
  log.info(
    "Registered SharedPreferences and Hive Boxes (incl. Budgets, Goals, Contributions).",
  );

  // --- Register REAL Hive DataSources (needed by Proxies) ---
  sl.registerLazySingleton<HiveExpenseLocalDataSource>(
    () => HiveExpenseLocalDataSource(sl()),
  );
  sl.registerLazySingleton<HiveIncomeLocalDataSource>(
    () => HiveIncomeLocalDataSource(sl()),
  );
  sl.registerLazySingleton<HiveAssetAccountLocalDataSource>(
    () => HiveAssetAccountLocalDataSource(sl()),
  );
  sl.registerLazySingleton<HiveBudgetLocalDataSource>(
    () => HiveBudgetLocalDataSource(sl()),
  );
  sl.registerLazySingleton<HiveGoalLocalDataSource>(
    () => HiveGoalLocalDataSource(sl()),
  );
  sl.registerLazySingleton<HiveContributionLocalDataSource>(
    () => HiveContributionLocalDataSource(sl()),
  );
  // Keep HiveCategoryLocalDataSource and HiveUserHistoryLocalDataSource registrations
  // (if they exist in categories_dependencies.dart, ensure they are registered there)
  log.info("Registered REAL Hive DataSources.");
  // --- END ---

  // *** Other External Dependencies (LazySingleton) ***
  if (!sl.isRegistered<Uuid>()) {
    sl.registerLazySingleton(() => const Uuid());
  }
  sl.registerLazySingleton(() => getDownloaderService());
  log.info("Registered Uuid generator.");

  // *** Call Feature Dependency Initializers ***
  log.info("Registering feature dependencies...");
  if (!sl.isRegistered<SettingsRepository>()) {
    // These will now register the PROXY datasources where applicable
    SettingsDependencies.register();
    DataManagementDependencies.register();
    IncomeDependencies.register();
    ExpensesDependencies.register();
    CategoriesDependencies.register();
    AccountDependencies.register();
    BudgetDependencies.register();
    GoalDependencies.register();
    TransactionsDependencies.register();
    DashboardDependencies.register();
    AnalyticsDependencies.register();
    ReportDependencies.register();
    RecurringTransactionsDependencies.register();
    log.info("Feature dependencies registered.");
  } else {
    log.warning(
      "Feature dependencies seem to be already registered. Skipping registration call.",
    );
  }

  log.info("Service Locator initialization complete.");
}

// --- publishDataChangedEvent ---
void publishDataChangedEvent({
  required DataChangeType type,
  required DataChangeReason reason,
}) {
  if (sl.isRegistered<StreamController<DataChangedEvent>>(
    instanceName: 'dataChangeController',
  )) {
    try {
      sl<StreamController<DataChangedEvent>>(
        instanceName: 'dataChangeController',
      ).add(DataChangedEvent(type: type, reason: reason));
      log.fine("Published DataChangedEvent: Type=$type, Reason=$reason");
    } catch (e, s) {
      log.severe("Error publishing DataChangedEvent: $e\n$s");
    }
  } else {
    log.warning(
      "Attempted to publish DataChangedEvent, but StreamController 'dataChangeController' is not registered.",
    );
  }
}
