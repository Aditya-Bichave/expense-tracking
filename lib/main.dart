// lib/main.dart
import 'dart:async';
import 'dart:io';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/constants/hive_constants.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
// Removed DemoModeService import, not directly needed here
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/sync/services/sync_coordinator.dart';
import 'package:expense_tracker/core/services/deep_link_service.dart';
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/router.dart';
// Removed InitialSetupScreen import, handled by router
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/core/utils/logger.dart';
export 'package:expense_tracker/core/utils/logger.dart';

File? _startupLogFile;

Future<void> _initFileLogger() async {
  try {
    final dir = await getApplicationDocumentsDirectory();
    _startupLogFile = File('${dir.path}/startup.log');
  } catch (_) {
    // If path_provider fails, continue without file logging
  }
}

Future<void> _writeStartupLog(String message) async {
  try {
    final file = _startupLogFile;
    if (file != null) {
      final timestamp = DateTime.now().toIso8601String();
      await file.writeAsString('$timestamp $message\n', mode: FileMode.append);
    }
  } catch (_) {
    // Swallow errors to avoid failing startup logging
  }
}

Future<void> _runMigrations(int fromVersion) async {
  log.info(
    'Running Hive migrations from v$fromVersion to '
    '${HiveConstants.dataVersion}',
  );
  // TODO: Implement actual migration logic when data models change.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFileLogger();
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  Intl.defaultLocale = locale.toLanguageTag();

  log.setLevel(Level.INFO, includeCallerInfo: false);
  log.info("==========================================");
  log.info(" Spend Savvy Application Starting...");
  await SupabaseClientProvider.initialize();
  log.info("==========================================");

  try {
    await Hive.initFlutter();
    final prefs = await SharedPreferences.getInstance();
    final storedVersion =
        prefs.getInt(HiveConstants.dataVersionKey) ?? HiveConstants.dataVersion;
    if (storedVersion < HiveConstants.dataVersion) {
      await _runMigrations(storedVersion);
      await prefs.setInt(
        HiveConstants.dataVersionKey,
        HiveConstants.dataVersion,
      );
    }

    // Register All Adapters BEFORE opening boxes
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(AssetAccountModelAdapter());
    Hive.registerAdapter(IncomeModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(UserHistoryRuleModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(GoalModelAdapter());
    Hive.registerAdapter(GoalContributionModelAdapter());
    Hive.registerAdapter(RecurringRuleModelAdapter());
    Hive.registerAdapter(RecurringRuleAuditLogModelAdapter());
    Hive.registerAdapter(OutboxItemAdapter());
    Hive.registerAdapter(EntityTypeAdapter());
    Hive.registerAdapter(OpTypeAdapter());

    log.info("Opening Hive boxes...");
    final expenseBox = await Hive.openBox<ExpenseModel>(
      HiveConstants.expenseBoxName,
    );
    final accountBox = await Hive.openBox<AssetAccountModel>(
      HiveConstants.accountBoxName,
    );
    final incomeBox = await Hive.openBox<IncomeModel>(
      HiveConstants.incomeBoxName,
    );
    final categoryBox = await Hive.openBox<CategoryModel>(
      HiveConstants.categoryBoxName,
    );
    final userHistoryBox = await Hive.openBox<UserHistoryRuleModel>(
      HiveConstants.userHistoryRuleBoxName,
    );
    final budgetBox = await Hive.openBox<BudgetModel>(
      HiveConstants.budgetBoxName,
    );
    final goalBox = await Hive.openBox<GoalModel>(HiveConstants.goalBoxName);
    final contributionBox = await Hive.openBox<GoalContributionModel>(
      HiveConstants.goalContributionBoxName,
    );
    final recurringRuleBox = await Hive.openBox<RecurringRuleModel>(
      HiveConstants.recurringRuleBoxName,
    );
    final recurringRuleAuditLogBox =
        await Hive.openBox<RecurringRuleAuditLogModel>(
          HiveConstants.recurringRuleAuditLogBoxName,
        );
    final outboxBox = await Hive.openBox<OutboxItem>('outbox');
        );
    log.info("All Hive boxes opened.");
    log.info("SharedPreferences instance obtained.");

    await initLocator(
      prefs: prefs,
      expenseBox: expenseBox,
      accountBox: accountBox,
      incomeBox: incomeBox,
      categoryBox: categoryBox,
      userHistoryBox: userHistoryBox,
      budgetBox: budgetBox,
      goalBox: goalBox,
      contributionBox: contributionBox,
      recurringRuleBox: recurringRuleBox,
      recurringRuleAuditLogBox: recurringRuleAuditLogBox,
      outboxBox: outboxBox,
    );
    log.info("Hive, SharedPreferences, and Service Locator initialized.");
    sl<SyncCoordinator>().initialize();
    DeepLinkService(AppRouter.router).initialize();
  } catch (e, s) {
    log.severe("!!! CRITICAL INITIALIZATION FAILURE !!!");
    log.severe("Error: $e");
    log.severe("Stack Trace: $s");
    await _writeStartupLog('Initialization failure: $e\n$s');
    log.severe("!!! APPLICATION CANNOT CONTINUE !!!");
    runApp(InitializationErrorApp(error: e));
    return;
  }

  // --- Global Bloc Providers ---
  runApp(
    MultiBlocProvider(
      providers: [
        // SettingsBloc MUST be provided early for Router redirect logic
        BlocProvider<SettingsBloc>(
          create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
          lazy: false, // Load settings immediately
        ),
        BlocProvider<DataManagementBloc>(
          create: (context) => sl<DataManagementBloc>(),
          lazy: true,
        ),
        BlocProvider<AccountListBloc>(
          create: (context) => sl<AccountListBloc>()..add(const LoadAccounts()),
          lazy: false, // Load immediately for dashboard dependencies
        ),
        BlocProvider<TransactionListBloc>(
          create: (context) =>
              sl<TransactionListBloc>()..add(const LoadTransactions()),
          lazy: false,
        ),
        BlocProvider<CategoryManagementBloc>(
          create: (context) =>
              sl<CategoryManagementBloc>()..add(const LoadCategories()),
          lazy: true,
        ),
        BlocProvider<BudgetListBloc>(
          create: (context) => sl<BudgetListBloc>()..add(const LoadBudgets()),
          lazy: false,
        ),
        BlocProvider<GoalListBloc>(
          create: (context) => sl<GoalListBloc>()..add(const LoadGoals()),
          lazy: false,
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => sl<DashboardBloc>()..add(const LoadDashboard()),
          lazy: false,
        ),
        BlocProvider<SummaryBloc>(
          create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
          lazy: true,
        ),
      ],
      child: const MyApp(), // Use MyApp directly, router handles initial screen
    ),
  );
}

class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // Provide default theme data even if settings failed
    final defaultThemePair = AppTheme.buildTheme(
      SettingsState.defaultUIMode,
      SettingsState.defaultPaletteIdentifier,
    );

    return MaterialApp(
      theme: defaultThemePair.light,
      darkTheme: defaultThemePair.dark,
      themeMode: SettingsState.defaultThemeMode,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red.shade700, size: 60),
                const SizedBox(height: 16),
                Text(
                  "Application Initialization Failed",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  "A critical error occurred during startup:\n\n${error.toString()}\n\nPlease restart the app. If the problem persists, contact support or check logs.",
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- MyApp (Consumes Router) ---
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = sl<LocalAuthentication>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkLock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkLock();
    }
  }

  Future<void> _checkLock() async {
    final settingsState = context.read<SettingsBloc>().state;
    if (!settingsState.isAppLockEnabled) return;
    try {
      await _localAuth.authenticate(
        localizedReason: 'Please authenticate to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (e) {
      log.warning('[MyApp] Authentication failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    final themeMode = settingsState.themeMode;
    final uiMode = settingsState.uiMode;
    final paletteId = settingsState.paletteIdentifier;

    final themeDataPair = AppTheme.buildTheme(uiMode, paletteId);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: themeDataPair.light,
      darkTheme: themeDataPair.dark,
      themeMode: themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
