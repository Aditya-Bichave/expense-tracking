import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'dart:async';
import 'package:expense_tracker/core/platform/platform_init.dart';
import 'package:expense_tracker/core/platform/logger_init.dart';

import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/constants/hive_constants.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/utils/bloc_observer.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
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
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
// import package:expense_tracker/features/reports/presentation/bloc/summary/summary_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
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

import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

Future<void> _runMigrations(int fromVersion) async {
  log.info(
    'Running Hive migrations from v$fromVersion to '
    '${HiveConstants.dataVersion}',
  );
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  await initPlatform(args);
  await initFileLogger();
  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  Intl.defaultLocale = locale.toLanguageTag();

  log.setLevel(Level.INFO, includeCallerInfo: false);
  log.info("==========================================");
  log.info(" Financial OS Application Starting...");
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

    log.info("Initializing Supabase...");
    await SupabaseClientProvider.initialize();

    log.info("Initializing Secure Storage & Encryption...");
    const secureStorage = FlutterSecureStorage();
    final secureStorageService = SecureStorageService(secureStorage);
    final hiveKey = await secureStorageService.getHiveKey();

    Hive.registerAdapter(ProfileModelAdapter());
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

    Hive.registerAdapter(SyncMutationModelAdapter());
    Hive.registerAdapter(SyncStatusAdapter());
    Hive.registerAdapter(OpTypeAdapter());

    Hive.registerAdapter(GroupModelAdapter());
    Hive.registerAdapter(GroupMemberModelAdapter());
    Hive.registerAdapter(GroupExpenseModelAdapter());
    Hive.registerAdapter(ExpensePayerModelAdapter());
    Hive.registerAdapter(ExpenseSplitModelAdapter());

    log.info("Opening Hive boxes...");
    final profileBoxFuture = Hive.openBox<ProfileModel>(
      'profile_box',
      encryptionCipher: HiveAesCipher(hiveKey),
    );
    final expenseBoxFuture = Hive.openBox<ExpenseModel>(
      HiveConstants.expenseBoxName,
    );
    final accountBoxFuture = Hive.openBox<AssetAccountModel>(
      HiveConstants.accountBoxName,
    );
    final incomeBoxFuture = Hive.openBox<IncomeModel>(
      HiveConstants.incomeBoxName,
    );
    final categoryBoxFuture = Hive.openBox<CategoryModel>(
      HiveConstants.categoryBoxName,
    );
    final userHistoryBoxFuture = Hive.openBox<UserHistoryRuleModel>(
      HiveConstants.userHistoryRuleBoxName,
    );
    final budgetBoxFuture = Hive.openBox<BudgetModel>(
      HiveConstants.budgetBoxName,
    );
    final goalBoxFuture = Hive.openBox<GoalModel>(HiveConstants.goalBoxName);
    final contributionBoxFuture = Hive.openBox<GoalContributionModel>(
      HiveConstants.goalContributionBoxName,
    );
    final recurringRuleBoxFuture = Hive.openBox<RecurringRuleModel>(
      HiveConstants.recurringRuleBoxName,
    );
    final recurringRuleAuditLogBoxFuture =
        Hive.openBox<RecurringRuleAuditLogModel>(
          HiveConstants.recurringRuleAuditLogBoxName,
        );

    final outboxBoxFuture = Hive.openBox<SyncMutationModel>(
      HiveConstants.outboxBoxName,
    );
    final groupBoxFuture = Hive.openBox<GroupModel>(HiveConstants.groupBoxName);
    final groupMemberBoxFuture = Hive.openBox<GroupMemberModel>(
      HiveConstants.groupMemberBoxName,
    );
    final groupExpenseBoxFuture = Hive.openBox<GroupExpenseModel>(
      HiveConstants.groupExpenseBoxName,
    );

    final profileBox = await profileBoxFuture;
    final expenseBox = await expenseBoxFuture;
    final accountBox = await accountBoxFuture;
    final incomeBox = await incomeBoxFuture;
    final categoryBox = await categoryBoxFuture;
    final userHistoryBox = await userHistoryBoxFuture;
    final budgetBox = await budgetBoxFuture;
    final goalBox = await goalBoxFuture;
    final contributionBox = await contributionBoxFuture;
    final recurringRuleBox = await recurringRuleBoxFuture;
    final recurringRuleAuditLogBox = await recurringRuleAuditLogBoxFuture;
    final outboxBox = await outboxBoxFuture;
    final groupBox = await groupBoxFuture;
    final groupMemberBox = await groupMemberBoxFuture;
    final groupExpenseBox = await groupExpenseBoxFuture;

    log.info("All Hive boxes opened.");
    log.info("SharedPreferences instance obtained.");

    await initLocator(
      secureStorageService: secureStorageService,
      profileBox: profileBox,
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
      groupBox: groupBox,
      groupMemberBox: groupMemberBox,
      groupExpenseBox: groupExpenseBox,
    );
    log.info("Hive, SharedPreferences, and Service Locator initialized.");
  } catch (e, s) {
    log.severe("!!! CRITICAL INITIALIZATION FAILURE !!!");
    log.severe("Error: $e");
    log.severe("Stack Trace: $s");
    await writeStartupLog('Initialization failure: $e\n$s');
    log.severe("!!! APPLICATION CANNOT CONTINUE !!!");
    runApp(InitializationErrorApp(error: e));
    return;
  }

  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
          lazy: false,
        ),
        BlocProvider<DataManagementBloc>(
          create: (context) => sl<DataManagementBloc>(),
          // lazy: true,
        ),
        BlocProvider<AccountListBloc>(
          create: (context) => sl<AccountListBloc>()..add(const LoadAccounts()),
          lazy: false,
        ),
        BlocProvider<TransactionListBloc>(
          create: (context) =>
              sl<TransactionListBloc>()..add(const LoadTransactions()),
          lazy: false,
        ),
        BlocProvider<CategoryManagementBloc>(
          create: (context) =>
              sl<CategoryManagementBloc>()..add(const LoadCategories()),
          // lazy: true,
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
        // BlocProvider<SummaryBloc>(
        // create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
        // lazy: true,
        //        ),
        BlocProvider<SessionCubit>(
          create: (context) => sl<SessionCubit>(),
          lazy: false,
        ),
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(AuthCheckStatus()),
          lazy: false,
        ),
        BlocProvider<GroupsBloc>(
          create: (context) => sl<GroupsBloc>()..add(LoadGroups()),
          lazy: false,
        ),
        BlocProvider<DeepLinkBloc>(
          create: (context) =>
              sl<DeepLinkBloc>()..add(DeepLinkStarted(args: args)),
          lazy: false,
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
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

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final diff = DateTime.now().difference(_pausedTime!);
        if (diff.inSeconds >= 60) {
          context.read<SessionCubit>().checkSession();
        }
      }
      _pausedTime = null;
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
