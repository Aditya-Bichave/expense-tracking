import 'dart:async';
import 'dart:ui';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/utils/app_initializer.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/core/constants/hive_constants.dart';
import 'package:expense_tracker/core/platform/logger_init.dart';
import 'package:expense_tracker/core/platform/platform_init.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/router.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:simple_logger/simple_logger.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/l10n/app_localizations.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';

Future<void> _runMigrations(int fromVersion) async {
  log.info(
    'Running Hive migrations from v$fromVersion to '
    '${HiveConstants.dataVersion}',
  );
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();

  // Global Error Handling
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    log.severe('Flutter Error: ${details.exception}\nStack: ${details.stack}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    log.severe('Platform Error: $error\nStack: $stack');
    return true;
  };

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
    // Use default secure options defined in SecureStorageService
    final secureStorageService = SecureStorageService();
    final hiveKey = await secureStorageService.getHiveKey();

    final boxes = await AppInitializer.initHiveBoxes(hiveKey);

    log.info("SharedPreferences instance obtained.");

    await initLocator(
      secureStorageService: secureStorageService,
      profileBox: boxes.profileBox,
      prefs: prefs,
      expenseBox: boxes.expenseBox,
      accountBox: boxes.accountBox,
      incomeBox: boxes.incomeBox,
      categoryBox: boxes.categoryBox,
      userHistoryBox: boxes.userHistoryBox,
      budgetBox: boxes.budgetBox,
      goalBox: boxes.goalBox,
      contributionBox: boxes.contributionBox,
      recurringRuleBox: boxes.recurringRuleBox,
      recurringRuleAuditLogBox: boxes.recurringRuleAuditLogBox,
      outboxBox: boxes.outboxBox,
      groupBox: boxes.groupBox,
      groupMemberBox: boxes.groupMemberBox,
      groupExpenseBox: boxes.groupExpenseBox,
    );
    log.info("Hive, SharedPreferences, and Service Locator initialized.");
  } catch (e, s) {
    log.severe("!!! CRITICAL INITIALIZATION FAILURE !!!");
    log.severe("Error: $e\nStack: $s");
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
          // lazy: false, // Changed to lazy: true (default) for performance
        ),
        BlocProvider<DataManagementBloc>(
          create: (context) => sl<DataManagementBloc>(),
          // lazy: true,
        ),
        BlocProvider<AccountListBloc>(
          create: (context) => sl<AccountListBloc>()..add(const LoadAccounts()),
        ),
        BlocProvider<TransactionListBloc>(
          create: (context) =>
              sl<TransactionListBloc>()..add(const LoadTransactions()),
          // lazy: false, // Changed to lazy: true (default) for performance
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
          // lazy: false, // Changed to lazy: true (default) for performance
        ),
        // BlocProvider<SummaryBloc>(
        // create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
        // lazy: true,
        //        ),
        BlocProvider<SessionCubit>(
          create: (context) => sl<SessionCubit>(),
          // lazy: false, // Eager load session for security
          lazy: false,
        ),
        BlocProvider<AuthBloc>(
          create: (context) => sl<AuthBloc>()..add(AuthCheckStatus()),
          lazy: false, // Eager load auth for redirects
        ),
        BlocProvider<GroupsBloc>(
          create: (context) => sl<GroupsBloc>()..add(LoadGroups()),
        ),
        BlocProvider<DeepLinkBloc>(
          create: (context) =>
              sl<DeepLinkBloc>()..add(DeepLinkStarted(args: args)),
          lazy: false, // Eager load deep links
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  Future<void> _resetApp(BuildContext context) async {
    try {
      // safely close Hive first
      try {
        await Hive.close();
      } catch (e) {
        log.warning('Failed to close Hive during reset: $e');
      }

      // Clear Secure Storage
      const secureStorage = FlutterSecureStorage();
      await secureStorage.deleteAll();

      // Clear Hive Boxes (Delete files)
      final dir = await getApplicationDocumentsDirectory();
      final files = dir.listSync();
      for (var file in files) {
        if (file.path.endsWith('.hive') || file.path.endsWith('.lock')) {
          try {
            // Attempt delete
            file.deleteSync();
          } catch (e) {
            log.warning('Failed to delete file ${file.path}: $e');
            // Consider retrying or ignoring if locked
          }
        }
      }

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
    }
  }

  @override
  Widget build(BuildContext context) {
    // Basic fallback theme
    final theme = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
    );

    final isCorruption = error is HiveKeyCorruptionException;

    return MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
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
                    if (isCorruption) ...[
                      const SizedBox(height: 24),
                      const Text(
                        "Your encryption key appears to be corrupted. You can reset the app data to recover, but all local data will be lost.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
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
  static const String _lastActiveKey = 'last_active_time';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkLastActiveTime();
  }

  Future<void> _checkLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    final lastActiveStr = prefs.getString(_lastActiveKey);
    if (lastActiveStr != null) {
      final lastActive = DateTime.tryParse(lastActiveStr);
      if (lastActive != null) {
        final diff = DateTime.now().difference(lastActive);
        // If we were inactive for more than 60 seconds (even across restarts), lock.
        if (diff.inSeconds >= 60) {
          if (mounted) {
            context.read<SessionCubit>().checkSession();
          }
        }
      }
    }
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
      _saveLastActiveTime();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final diff = DateTime.now().difference(_pausedTime!);
        if (diff.inSeconds >= 60) {
          context.read<SessionCubit>().checkSession();
        }
      }
      _pausedTime = null;
      _clearLastActiveTime();
    }
  }

  Future<void> _saveLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
  }

  Future<void> _clearLastActiveTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastActiveKey);
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
