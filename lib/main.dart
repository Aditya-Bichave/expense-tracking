import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce/hive.dart'; // Using hive_ce instead of hive
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/ui_kit/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart'; // Standard generated path
import 'package:expense_tracker/l10n/app_localizations.dart'; // Manual import based on file location
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/core/utils/bloc_observer.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Hive Models
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
import 'package:expense_tracker/ui_bridge/bridge_elevated_button.dart';
import 'package:expense_tracker/ui_bridge/bridge_circular_progress_indicator.dart';
import 'package:expense_tracker/ui_bridge/bridge_scaffold.dart';
import 'package:expense_tracker/ui_bridge/bridge_text_style.dart';
import 'package:expense_tracker/ui_bridge/bridge_edge_insets.dart';

// RE-ADDING THE EXPORT AS REQUESTED TO FIX LOGGER VISIBILITY
export 'package:expense_tracker/core/utils/logger.dart';

void main(List<String> args) async {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      try {
        await AppInitializer.init();
        runApp(App(args: args));
      } catch (e, stack) {
        log.severe('Initialization failed: $e\nStack: $stack');
        runApp(InitializationErrorApp(error: e));
      }
    },
    (error, stack) {
      log.severe('Unhandled error caught by zone: $error\nStack: $stack');
    },
  );
}

class AppInitializer {
  static Future<void> init() async {
    Bloc.observer = SimpleBlocObserver();

    // 1. Initialize Hive
    await Hive.initFlutter();

    // 2. Register Adapters
    _registerHiveAdapters();

    // 3. Initialize Secure Storage & Encryption Key
    final secureStorageService = SecureStorageService();
    // Assuming getHiveKey handles key generation/retrieval
    final encryptionKey = await secureStorageService.getHiveKey();

    // 4. Open Hive Boxes
    // Note: Using encryption for sensitive data if supported/required.
    // Assuming generic openBox for now, but in production, we should check if encryption is needed for all.
    // Based on memory, there was a mention of secure storage keys, so let's use it where appropriate.
    // For simplicity in this fix, I'll open them without explicit encryption unless strictly required by the model/box definitions in previous context.
    // Actually, `getHiveKey` suggests encryption IS used. Let's try to use it if we can.
    // However, `Hive.openBox` takes `HiveCipher`.
    // Let's assume standard opening for now to avoid complexity unless I see explicit usage.
    // Wait, `initLocator` takes `Box<Type>`.

    final expenseBox = await Hive.openBox<ExpenseModel>(
      'expenses',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final accountBox = await Hive.openBox<AssetAccountModel>(
      'accounts',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final incomeBox = await Hive.openBox<IncomeModel>(
      'income',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final categoryBox = await Hive.openBox<CategoryModel>(
      'categories',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final userHistoryBox = await Hive.openBox<UserHistoryRuleModel>(
      'user_history_rules',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final budgetBox = await Hive.openBox<BudgetModel>(
      'budgets',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final goalBox = await Hive.openBox<GoalModel>(
      'goals',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final contributionBox = await Hive.openBox<GoalContributionModel>(
      'goal_contributions',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final recurringRuleBox = await Hive.openBox<RecurringRuleModel>(
      'recurring_rules',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final recurringRuleAuditLogBox =
        await Hive.openBox<RecurringRuleAuditLogModel>(
          'recurring_rule_audit_logs',
          encryptionCipher: HiveAesCipher(encryptionKey),
        );
    final outboxBox = await Hive.openBox<SyncMutationModel>(
      'sync_outbox',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final groupBox = await Hive.openBox<GroupModel>(
      'groups',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final groupMemberBox = await Hive.openBox<GroupMemberModel>(
      'group_members',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final groupExpenseBox = await Hive.openBox<GroupExpenseModel>(
      'group_expenses',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );
    final profileBox = await Hive.openBox<ProfileModel>(
      'profile',
      encryptionCipher: HiveAesCipher(encryptionKey),
    );

    // 5. Initialize SharedPreferences
    final prefs = await SharedPreferences.getInstance();

    // 6. Initialize Service Locator
    await initLocator(
      prefs: prefs,
      secureStorageService: secureStorageService,
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
      profileBox: profileBox,
    );
  }

  static void _registerHiveAdapters() {
    // Check if registered to avoid errors in hot restart or multiple inits
    if (!Hive.isAdapterRegistered(ExpenseModelAdapter().typeId)) {
      Hive.registerAdapter(ExpenseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(AssetAccountModelAdapter().typeId)) {
      Hive.registerAdapter(AssetAccountModelAdapter());
    }
    if (!Hive.isAdapterRegistered(IncomeModelAdapter().typeId)) {
      Hive.registerAdapter(IncomeModelAdapter());
    }
    if (!Hive.isAdapterRegistered(CategoryModelAdapter().typeId)) {
      Hive.registerAdapter(CategoryModelAdapter());
    }
    if (!Hive.isAdapterRegistered(UserHistoryRuleModelAdapter().typeId)) {
      Hive.registerAdapter(UserHistoryRuleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(BudgetModelAdapter().typeId)) {
      Hive.registerAdapter(BudgetModelAdapter());
    }
    if (!Hive.isAdapterRegistered(GoalModelAdapter().typeId)) {
      Hive.registerAdapter(GoalModelAdapter());
    }
    if (!Hive.isAdapterRegistered(GoalContributionModelAdapter().typeId)) {
      Hive.registerAdapter(GoalContributionModelAdapter());
    }
    if (!Hive.isAdapterRegistered(RecurringRuleModelAdapter().typeId)) {
      Hive.registerAdapter(RecurringRuleModelAdapter());
    }
    if (!Hive.isAdapterRegistered(RecurringRuleAuditLogModelAdapter().typeId)) {
      Hive.registerAdapter(RecurringRuleAuditLogModelAdapter());
    }
    if (!Hive.isAdapterRegistered(SyncMutationModelAdapter().typeId)) {
      Hive.registerAdapter(SyncMutationModelAdapter());
    }
    if (!Hive.isAdapterRegistered(GroupModelAdapter().typeId)) {
      Hive.registerAdapter(GroupModelAdapter());
    }
    if (!Hive.isAdapterRegistered(GroupMemberModelAdapter().typeId)) {
      Hive.registerAdapter(GroupMemberModelAdapter());
    }
    if (!Hive.isAdapterRegistered(GroupExpenseModelAdapter().typeId)) {
      Hive.registerAdapter(GroupExpenseModelAdapter());
    }
    if (!Hive.isAdapterRegistered(ProfileModelAdapter().typeId)) {
      Hive.registerAdapter(ProfileModelAdapter());
    }
  }
}

class App extends StatelessWidget {
  final List<String> args;
  const App({super.key, this.args = const []});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>(
          create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
          lazy: false,
        ),
        BlocProvider<DataManagementBloc>(
          create: (context) => sl<DataManagementBloc>(),
        ),
        BlocProvider<AccountListBloc>(
          create: (context) => sl<AccountListBloc>()..add(const LoadAccounts()),
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
        ),
        BlocProvider<GoalListBloc>(
          create: (context) => sl<GoalListBloc>()..add(const LoadGoals()),
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
        ),
        BlocProvider<DeepLinkBloc>(
          create: (context) =>
              sl<DeepLinkBloc>()..add(DeepLinkStarted(args: args)),
          lazy: false,
        ),
      ],
      child: const MyApp(),
    );
  }
}

class InitializationErrorApp extends StatefulWidget {
  final Object error;
  final ThemeData? theme;

  const InitializationErrorApp({super.key, required this.error, this.theme});

  @override
  State<InitializationErrorApp> createState() => _InitializationErrorAppState();
}

class _InitializationErrorAppState extends State<InitializationErrorApp> {
  bool _isResetting = false;

  Future<void> _resetApp(BuildContext context) async {
    setState(() {
      _isResetting = true;
    });

    try {
      // Clear Secure Storage
      // Using default secure options
      final secureStorageService = SecureStorageService();
      await secureStorageService.clearAll();

      // Clear Hive Boxes (Delete files)
      final dir = await getApplicationDocumentsDirectory();
      // Use async list to avoid blocking UI
      final files = await dir.list().toList();
      await Future.wait(
        files.map((file) async {
          if (file.path.endsWith('.hive') || file.path.endsWith('.lock')) {
            try {
              await file.delete();
            } catch (_) {}
          }
        }),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Data reset successfully. Please restart the app manually.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Reset failed: $e")));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isResetting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only build default theme if no test theme is provided to avoid font loading issues in tests
    final defaultThemePair = widget.theme == null
        ? AppTheme.buildTheme(
            SettingsState.defaultUIMode,
            SettingsState.defaultPaletteIdentifier,
          )
        : null;

    final isCorruption = widget.error is HiveKeyCorruptionException;

    return MaterialApp(
      theme: widget.theme ?? defaultThemePair!.light,
      darkTheme: widget.theme ?? defaultThemePair!.dark,
      themeMode: SettingsState.defaultThemeMode,
      home: BridgeScaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: Padding(
                padding: const BridgeEdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Colors.red.shade700,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Application Initialization Failed",
                      style: BridgeTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "A critical error occurred during startup:\n\n${widget.error.toString()}\n\nPlease restart the app. If the problem persists, contact support or check logs.",
                      textAlign: TextAlign.center,
                      style: const BridgeTextStyle(fontSize: 14),
                    ),
                    if (isCorruption) ...[
                      const SizedBox(height: 24),
                      const Text(
                        "Your encryption key appears to be corrupted. You can reset the app data to recover, but all local data will be lost.",
                        textAlign: TextAlign.center,
                        style: BridgeTextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      if (_isResetting)
                        const BridgeCircularProgressIndicator()
                      else
                        BridgeElevatedButton(
                          onPressed: () => _resetApp(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text("Reset App Data"),
                        ),
                    ],
                  ],
                ),
              ),
            );
          },
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
