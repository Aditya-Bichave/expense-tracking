import 'dart:async';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source_impl.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/main.dart';

import 'package:expense_tracker/core/events/data_change_event.dart';

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

import 'package:expense_tracker/core/di/service_configurations/auth_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/profile_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/groups_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/group_expenses_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/add_expense_dependencies.dart';
import 'package:expense_tracker/core/di/service_configurations/sync_dependencies.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/sync/sync_coordinator.dart';

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

import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';

import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_local_data_source.dart';
import 'package:expense_tracker/features/goals/data/datasources/goal_contribution_local_data_source.dart';

import 'package:expense_tracker/core/services/secure_storage_service.dart';

final sl = GetIt.instance;

Future<void> initLocator({
  required SharedPreferences prefs,
  required SecureStorageService secureStorageService,
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
  required Box<SyncMutationModel> outboxBox,
  required Box<GroupModel> groupBox,
  required Box<GroupMemberModel> groupMemberBox,
  required Box<GroupExpenseModel> groupExpenseBox,
  required Box<ProfileModel> profileBox,
}) async {
  log.info("Initializing Service Locator...");

  if (!sl.isRegistered<DemoModeService>()) {
    sl.registerLazySingleton<DemoModeService>(() => DemoModeService());
  }

  if (!sl.isRegistered<Clock>()) {
    sl.registerLazySingleton<Clock>(() => SystemClock());
  }

  if (!sl.isRegistered<StreamController<DataChangedEvent>>()) {
    final dataChangeController = StreamController<DataChangedEvent>.broadcast();
    sl.registerSingleton<StreamController<DataChangedEvent>>(
      dataChangeController,
      instanceName: 'dataChangeController',
    );
    sl.registerSingleton<Stream<DataChangedEvent>>(dataChangeController.stream);
  }

  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerLazySingleton<SharedPreferences>(() => prefs);
  }
  if (!sl.isRegistered<SecureStorageService>()) {
    sl.registerLazySingleton<SecureStorageService>(() => secureStorageService);
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

  if (!sl.isRegistered<Box<SyncMutationModel>>()) {
    sl.registerLazySingleton<Box<SyncMutationModel>>(() => outboxBox);
  }
  if (!sl.isRegistered<Box<GroupModel>>()) {
    sl.registerLazySingleton<Box<GroupModel>>(() => groupBox);
  }
  if (!sl.isRegistered<Box<GroupMemberModel>>()) {
    sl.registerLazySingleton<Box<GroupMemberModel>>(() => groupMemberBox);
  }
  if (!sl.isRegistered<Box<GroupExpenseModel>>()) {
    sl.registerLazySingleton<Box<GroupExpenseModel>>(() => groupExpenseBox);
  }
  if (!sl.isRegistered<Box<ProfileModel>>()) {
    sl.registerLazySingleton<Box<ProfileModel>>(() => profileBox);
  }

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

  if (!sl.isRegistered<Uuid>()) {
    sl.registerLazySingleton(() => const Uuid());
  }
  sl.registerLazySingleton(() => getDownloaderService());

  sl.registerLazySingleton(() => SupabaseClientProvider.client);

  if (!sl.isRegistered<SettingsRepository>()) {
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

    AuthDependencies.register();
    ProfileDependencies.register();
    SyncDependencies.register();
    GroupsDependencies.register();
    GroupExpensesDependencies.register();
    AddExpenseDependencies.register();
  }

  if (sl.isRegistered<SyncCoordinator>()) {
    sl<SyncCoordinator>().initialize();
  }

  log.info("Service Locator initialization complete.");
}

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
    } catch (e, s) {
      log.severe("Error publishing DataChangedEvent: $e\n$s");
    }
  }
}
