// lib/main.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logger/simple_logger.dart';

// Import Core dependencies
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/core/constants/hive_constants.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';

// Import Models & Adapters for Hive registration
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';
import 'package:expense_tracker/features/budgets/data/models/budget_model.dart';
import 'package:expense_tracker/features/goals/data/models/goal_model.dart'; // ADDED
import 'package:expense_tracker/features/goals/data/models/goal_contribution_model.dart'; // ADDED

// Import Blocs needed globally
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list/goal_list_bloc.dart'; // ADDED

final log = SimpleLogger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log.setLevel(Level.INFO, includeCallerInfo: false); // Adjusted default level
  log.info("==========================================");
  log.info(" Spend Savvy Application Starting...");
  log.info("==========================================");

  try {
    await Hive.initFlutter();
    // Register All Adapters BEFORE opening boxes
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(AssetAccountModelAdapter());
    Hive.registerAdapter(IncomeModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(UserHistoryRuleModelAdapter());
    Hive.registerAdapter(BudgetModelAdapter());
    Hive.registerAdapter(GoalModelAdapter()); // --- ADDED GOAL ADAPTER ---
    Hive.registerAdapter(
        GoalContributionModelAdapter()); // --- ADDED CONTRIBUTION ADAPTER ---

    log.info("Opening Hive boxes...");
    final expenseBox =
        await Hive.openBox<ExpenseModel>(HiveConstants.expenseBoxName);
    final accountBox =
        await Hive.openBox<AssetAccountModel>(HiveConstants.accountBoxName);
    final incomeBox =
        await Hive.openBox<IncomeModel>(HiveConstants.incomeBoxName);
    final categoryBox =
        await Hive.openBox<CategoryModel>(HiveConstants.categoryBoxName);
    final userHistoryBox = await Hive.openBox<UserHistoryRuleModel>(
        HiveConstants.userHistoryRuleBoxName);
    final budgetBox =
        await Hive.openBox<BudgetModel>(HiveConstants.budgetBoxName);
    final goalBox = await Hive.openBox<GoalModel>(
        HiveConstants.goalBoxName); // --- ADDED OPEN GOAL BOX ---
    final contributionBox = await Hive.openBox<GoalContributionModel>(
        HiveConstants
            .goalContributionBoxName); // --- ADDED OPEN CONTRIBUTION BOX ---
    log.info("All Hive boxes opened.");

    final prefs = await SharedPreferences.getInstance();
    log.info("SharedPreferences instance obtained.");

    await initLocator(
      prefs: prefs,
      expenseBox: expenseBox,
      accountBox: accountBox,
      incomeBox: incomeBox,
      categoryBox: categoryBox,
      userHistoryBox: userHistoryBox,
      budgetBox: budgetBox,
      goalBox: goalBox, // --- PASSED GOAL BOX ---
      contributionBox: contributionBox, // --- PASSED CONTRIBUTION BOX ---
    );
    log.info("Hive, SharedPreferences, and Service Locator initialized.");
  } catch (e, s) {
    log.severe("!!! CRITICAL INITIALIZATION FAILURE !!!");
    log.severe("Error: $e");
    log.severe("Stack Trace: $s");
    log.severe("!!! APPLICATION CANNOT CONTINUE !!!");
    runApp(InitializationErrorApp(error: e));
    return;
  }

  // --- Global Bloc Providers ---
  runApp(MultiBlocProvider(
    providers: [
      BlocProvider<SettingsBloc>(
        create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
        lazy: false,
      ),
      BlocProvider<DataManagementBloc>(
        create: (context) => sl<DataManagementBloc>(),
        lazy: true,
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
        lazy: false,
      ),
      BlocProvider<BudgetListBloc>(
        create: (context) => sl<BudgetListBloc>()..add(const LoadBudgets()),
        lazy: false,
      ),
      BlocProvider<GoalListBloc>(
        // --- ADDED GOAL LIST BLOC ---
        create: (context) => sl<GoalListBloc>()..add(const LoadGoals()),
        lazy: false,
      ),
      BlocProvider<DashboardBloc>(
        create: (context) => sl<DashboardBloc>()..add(const LoadDashboard()),
        lazy: false,
      ),
      BlocProvider<SummaryBloc>(
        create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
        lazy: false,
      ),
      // AddEdit Blocs are typically provided closer to where they are needed (e.g., via BlocProvider.value or on the specific route/page)
    ],
    child: const AuthWrapper(),
  ));
}

// ... (InitializationErrorApp class remains the same) ...
class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    final defaultTheme = AppTheme.buildTheme(
      SettingsState.defaultUIMode,
      SettingsState.defaultPaletteIdentifier,
    );
    return MaterialApp(
      theme: defaultTheme.light,
      darkTheme: defaultTheme.dark,
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
                      color: Colors.red.shade900),
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

// ... (AuthWrapper class remains the same) ...
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isCheckingAuth = true;
  bool _needsAuth = false;
  bool _isAuthenticated = false;
  bool _justAuthenticated = false;
  Timer? _authCooldownTimer;
  StreamSubscription? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _listenForSettingsAndCheckAuth();
      }
    });
    log.info("[AuthWrapper] Initialized and observing lifecycle.");
  }

  void _listenForSettingsAndCheckAuth() {
    try {
      final settingsBloc = BlocProvider.of<SettingsBloc>(context);
      if (settingsBloc.state.status == SettingsStatus.loaded ||
          settingsBloc.state.status == SettingsStatus.error) {
        log.info(
            "[AuthWrapper] Settings already loaded/error state: ${settingsBloc.state.status}. Checking initial auth.");
        _checkInitialAuthState(settingsBloc.state);
      } else {
        log.info(
            "[AuthWrapper] Settings not loaded yet (state: ${settingsBloc.state.status}). Listening to stream.");
        _settingsSubscription?.cancel();
        _settingsSubscription = settingsBloc.stream.listen((state) {
          if (state.status == SettingsStatus.loaded ||
              state.status == SettingsStatus.error) {
            log.info(
                "[AuthWrapper] Settings stream emitted ${state.status}. Checking initial auth state.");
            _checkInitialAuthState(state);
            _settingsSubscription?.cancel();
            _settingsSubscription = null;
            log.info(
                "[AuthWrapper] Settings subscription cancelled after first load/error.");
          }
        });
      }
    } catch (e) {
      log.severe(
          "[AuthWrapper] Error accessing SettingsBloc during initial listener setup: $e. Retrying shortly.");
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) _listenForSettingsAndCheckAuth();
      });
    }
  }

  @override
  void dispose() {
    log.info("[AuthWrapper] Disposing.");
    WidgetsBinding.instance.removeObserver(this);
    _authCooldownTimer?.cancel();
    _settingsSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    log.info("[AuthWrapper] AppLifecycleState changed: $state");
    if (!mounted) return;

    bool lockEnabledNow = false;
    try {
      lockEnabledNow = context.read<SettingsBloc>().state.isAppLockEnabled;
    } catch (e) {
      log.warning(
          "[AuthWrapper] Could not read SettingsBloc in didChangeAppLifecycleState: $e");
    }

    if (state == AppLifecycleState.resumed) {
      _needsAuth = lockEnabledNow;
      if (lockEnabledNow && !_isAuthenticated && !_justAuthenticated) {
        log.info(
            "[AuthWrapper] App resumed, needs auth and not recently authenticated. Triggering authenticate.");
        _authenticate();
      } else if (lockEnabledNow && _justAuthenticated) {
        log.info(
            "[AuthWrapper] App resumed, just authenticated, skipping immediate auth. Starting cooldown.");
        _startAuthCooldown();
      } else if (!lockEnabledNow && !_isAuthenticated) {
        log.info(
            "[AuthWrapper] App resumed, lock not enabled. Granting access.");
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
      } else {
        log.info(
            "[AuthWrapper] App resumed. Lock Enabled: $lockEnabledNow, Authenticated: $_isAuthenticated, Just Auth: $_justAuthenticated. No action needed.");
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _authCooldownTimer?.cancel();
      if (lockEnabledNow) {
        log.info(
            "[AuthWrapper] App paused/inactive, lock enabled. Resetting auth state if currently authenticated.");
        if (_isAuthenticated || _justAuthenticated) {
          setState(() {
            _isAuthenticated = false;
            _justAuthenticated = false;
          });
        }
      } else {
        log.info(
            "[AuthWrapper] App paused/inactive, lock NOT enabled. Auth state remains.");
      }
    }
  }

  Future<void> _checkInitialAuthState(SettingsState settingsState) async {
    if (!mounted) return;
    final bool appLockEnabled = settingsState.isAppLockEnabled;
    _needsAuth = appLockEnabled;
    log.info("[AuthWrapper] Initial check: App Lock Enabled = $appLockEnabled");

    if (appLockEnabled) {
      if (!_isAuthenticated) {
        log.info(
            "[AuthWrapper] App lock enabled, attempting initial authentication.");
        _authenticate();
      } else {
        log.info(
            "[AuthWrapper] App lock enabled, but already authenticated. Skipping initial auth prompt.");
        setState(() {
          _isCheckingAuth = false;
        });
      }
    } else {
      log.info("[AuthWrapper] App lock disabled, granting access.");
      if (!_isAuthenticated) {
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
      } else {
        setState(() {
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> _authenticate({bool isRetry = false}) async {
    if (!mounted) return;
    if (_isCheckingAuth && !isRetry) {
      log.warning(
          "[AuthWrapper] Authentication already in progress. Ignoring duplicate request.");
      return;
    }
    if (_isAuthenticated && !isRetry) {
      log.info(
          "[AuthWrapper] Already authenticated. Skipping authentication prompt.");
      setState(() {
        _isCheckingAuth = false;
      });
      return;
    }

    setState(() {
      _isCheckingAuth = true;
    });
    log.info(
        "[AuthWrapper] Starting authentication process... (Is Retry: $isRetry)");

    bool didAuthenticate = false;
    String? errorMsg;

    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        errorMsg = "Device authentication not available or not set up.";
        log.warning(
            "[AuthWrapper] Authentication check failed: Device not supported or auth not set up.");
        if (mounted) _showAuthErrorSnackbar(errorMsg);
      } else {
        log.info(
            "[AuthWrapper] Device supports auth. Calling local_auth.authenticate...");
        didAuthenticate = await _localAuth.authenticate(
          localizedReason:
              'Please authenticate to access ${AppConstants.appName}',
          options: const AuthenticationOptions(
            stickyAuth: true,
            useErrorDialogs: true,
            biometricOnly: false,
          ),
        );
        log.info("[AuthWrapper] Authentication result: $didAuthenticate");
      }
    } on PlatformException catch (e, s) {
      errorMsg = "Authentication Error: ${e.message ?? e.code}";
      log.severe("[AuthWrapper] PlatformException during authenticate: $e\n$s");
      if (mounted && e.code != 'auth_in_progress' && e.code != 'user_cancel') {
        _showAuthErrorSnackbar(errorMsg);
      }
    } catch (e, s) {
      errorMsg = "An unexpected error occurred during authentication.";
      log.severe("[AuthWrapper] Exception during authenticate: $e\n$s");
      if (mounted) _showAuthErrorSnackbar(errorMsg);
    } finally {
      if (mounted) {
        log.info(
            "[AuthWrapper] Authentication attempt finished. Updating state: Authenticated=$didAuthenticate");
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isCheckingAuth = false;
          if (didAuthenticate) {
            _justAuthenticated = true;
            _startAuthCooldown();
          }
        });
      } else {
        log.warning(
            "[AuthWrapper] Authentication finished, but widget not mounted.");
      }
    }
  }

  void _startAuthCooldown() {
    _authCooldownTimer?.cancel();
    _authCooldownTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _justAuthenticated = false;
        });
        log.info("[AuthWrapper] Auth cooldown finished.");
      }
    });
    log.info("[AuthWrapper] Auth cooldown started.");
  }

  void _showAuthErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 4),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    SettingsState settingsState;
    try {
      settingsState = context.watch<SettingsBloc>().state;
    } catch (e) {
      log.warning(
          "[AuthWrapper] Error watching SettingsBloc state in build: $e. Using defaults.");
      settingsState = const SettingsState();
    }

    final currentThemeMode = settingsState.themeMode;
    final currentUiMode = settingsState.uiMode;
    final currentPaletteIdentifier = settingsState.paletteIdentifier;

    log.fine(
        "[AuthWrapper] Build: UIMode=$currentUiMode, Palette=$currentPaletteIdentifier, Brightness=$currentThemeMode, NeedsAuth=$_needsAuth, IsAuthenticated=$_isAuthenticated, IsCheckingAuth=$_isCheckingAuth");

    final AppThemeDataPair finalThemeDataPair =
        AppTheme.buildTheme(currentUiMode, currentPaletteIdentifier);
    final lightTheme = finalThemeDataPair.light;
    final darkTheme = finalThemeDataPair.dark;

    Widget content;
    if (_isCheckingAuth && !_isAuthenticated && _needsAuth) {
      log.fine("[AuthWrapper UI] Showing Loading Screen (during auth check).");
      content =
          const Scaffold(body: Center(child: CircularProgressIndicator()));
    } else if (_needsAuth && !_isAuthenticated) {
      log.fine("[AuthWrapper UI] Showing Locked Screen.");
      content = Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_person_outlined,
                    size: 80, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 24),
                Text('Authentication Required',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 12),
                Text(AppConstants.appName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary)),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12)),
                  icon: const Icon(Icons.fingerprint),
                  label: const Text('Authenticate / Retry'),
                  onPressed: _isCheckingAuth
                      ? null
                      : () => _authenticate(isRetry: true),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      log.fine(
          "[AuthWrapper UI] Showing Main App (MyApp). Authenticated=$_isAuthenticated, NeedsAuth=$_needsAuth");
      content = MyApp(
          lightTheme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentThemeMode);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: currentThemeMode,
      home: content,
    );
  }
}

// ... (MyApp class remains the same) ...
class MyApp extends StatelessWidget {
  final ThemeData lightTheme;
  final ThemeData darkTheme;
  final ThemeMode themeMode;

  const MyApp({
    super.key,
    required this.lightTheme,
    required this.darkTheme,
    required this.themeMode,
  });

  @override
  Widget build(BuildContext context) {
    final GoRouter router = AppRouter.router;
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
