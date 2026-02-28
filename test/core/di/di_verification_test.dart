import 'dart:async';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
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
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/features/accounts/data/datasources/asset_account_local_data_source.dart';
import 'package:expense_tracker/core/sync/sync_coordinator.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockBox<T> extends Mock implements Box<T> {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockConnectivity extends Mock implements Connectivity {}

class MockSyncCoordinator extends Mock implements SyncCoordinator {}

void main() {
  setUp(() async {
    await sl.reset();
  });

  test('initLocator successfully registers all dependencies', () async {
    final prefs = MockSharedPreferences();
    final secureStorage = MockSecureStorageService();
    final supabaseClient = MockSupabaseClient();
    final connectivity = MockConnectivity();
    final syncCoordinator = MockSyncCoordinator();

    // Pre-register mocks that are problematic to initialize in tests
    sl.registerSingleton<SupabaseClient>(supabaseClient);
    sl.registerSingleton<Connectivity>(connectivity);
    sl.registerSingleton<SyncCoordinator>(syncCoordinator);

    // Mock initialize call since it's called in initLocator
    when(() => syncCoordinator.initialize()).thenAnswer((_) async => {});

    await initLocator(
      prefs: prefs,
      secureStorageService: secureStorage,
      expenseBox: MockBox<ExpenseModel>(),
      accountBox: MockBox<AssetAccountModel>(),
      incomeBox: MockBox<IncomeModel>(),
      categoryBox: MockBox<CategoryModel>(),
      userHistoryBox: MockBox<UserHistoryRuleModel>(),
      budgetBox: MockBox<BudgetModel>(),
      goalBox: MockBox<GoalModel>(),
      contributionBox: MockBox<GoalContributionModel>(),
      recurringRuleBox: MockBox<RecurringRuleModel>(),
      recurringRuleAuditLogBox: MockBox<RecurringRuleAuditLogModel>(),
      outboxBox: MockBox<SyncMutationModel>(),
      groupBox: MockBox<GroupModel>(),
      groupMemberBox: MockBox<GroupMemberModel>(),
      groupExpenseBox: MockBox<GroupExpenseModel>(),
      profileBox: MockBox<ProfileModel>(),
    );

    // Basic verification of some key registered types
    expect(sl.isRegistered<SharedPreferences>(), isTrue);
    expect(sl.isRegistered<SecureStorageService>(), isTrue);
    expect(sl.isRegistered<Box<ExpenseModel>>(), isTrue);
    expect(sl.isRegistered<Stream<DataChangedEvent>>(), isTrue);
    expect(sl.isRegistered<SupabaseClient>(), isTrue);
    expect(sl.isRegistered<SyncCoordinator>(), isTrue);

    // Check if one of the feature dependencies is registered
    // AccountDependencies.register() registers AssetAccountLocalDataSource
    expect(sl.isRegistered<AssetAccountLocalDataSource>(), isTrue);
  });
}
