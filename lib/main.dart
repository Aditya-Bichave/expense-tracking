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

// Import Models for Hive registration
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/categories/data/models/category_model.dart';
import 'package:expense_tracker/features/categories/data/models/user_history_rule_model.dart';

// Import Blocs needed globally
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
// --- ADDED Data Management Bloc Import ---
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';

final log = SimpleLogger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log.setLevel(Level.WARNING, includeCallerInfo: false);
  log.info("==========================================");
  log.info(" Spend Savvy Application Starting...");
  log.info("==========================================");

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(AssetAccountModelAdapter());
    Hive.registerAdapter(IncomeModelAdapter());
    Hive.registerAdapter(CategoryModelAdapter());
    Hive.registerAdapter(UserHistoryRuleModelAdapter());

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
    final prefs = await SharedPreferences.getInstance();

    await initLocator(
      prefs: prefs,
      expenseBox: expenseBox,
      accountBox: accountBox,
      incomeBox: incomeBox,
      categoryBox: categoryBox,
      userHistoryBox: userHistoryBox,
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
      // --- ADDED DataManagementBloc Provider ---
      BlocProvider<DataManagementBloc>(
        create: (context) => sl<DataManagementBloc>(),
        lazy: true, // Can be lazy as it's mostly user-triggered
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
      BlocProvider<DashboardBloc>(
        create: (context) => sl<DashboardBloc>()..add(const LoadDashboard()),
        lazy: false,
      ),
      BlocProvider<SummaryBloc>(
        create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
        lazy: false,
      ),
    ],
    child: const AuthWrapper(), // AuthWrapper handles auth and then loads MyApp
  ));
}

// ... (Rest of main.dart - InitializationErrorApp, AuthWrapper, MyApp - remains the same) ...
class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // Use default theme values as SettingsBloc might not be available
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

// Handles Authentication check before showing the main app
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
    // Use addPostFrameCallback to ensure context is ready for Bloc access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _listenForSettingsAndCheckAuth();
      }
    });
    log.info("[AuthWrapper] Initialized and observing lifecycle.");
  }

  void _listenForSettingsAndCheckAuth() {
    // Ensure SettingsBloc is accessed safely
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
        _settingsSubscription?.cancel(); // Cancel previous if any
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
      // Retry after a short delay if BlocProvider wasn't ready
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

    // Use context.read safely, assuming context is valid here
    bool lockEnabledNow = false;
    try {
      lockEnabledNow = context.read<SettingsBloc>().state.isAppLockEnabled;
    } catch (e) {
      log.warning(
          "[AuthWrapper] Could not read SettingsBloc in didChangeAppLifecycleState: $e");
      // Assume lock disabled if state is inaccessible? Or re-check later?
    }

    if (state == AppLifecycleState.resumed) {
      _needsAuth = lockEnabledNow; // Re-evaluate need for auth
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
        // If lock was turned off while app was paused, grant access now
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false; // Ensure checking state is false
        });
      } else {
        log.info(
            "[AuthWrapper] App resumed. Lock Enabled: $lockEnabledNow, Authenticated: $_isAuthenticated, Just Auth: $_justAuthenticated. No action needed.");
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _authCooldownTimer?.cancel(); // Cancel cooldown if app is paused
      if (lockEnabledNow) {
        log.info(
            "[AuthWrapper] App paused/inactive, lock enabled. Resetting auth state if currently authenticated.");
        if (_isAuthenticated || _justAuthenticated) {
          // Only update state if needed to avoid unnecessary rebuilds
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
      // Only authenticate if not already authenticated (e.g., from a previous session)
      if (!_isAuthenticated) {
        log.info(
            "[AuthWrapper] App lock enabled, attempting initial authentication.");
        _authenticate(); // Trigger authentication flow
      } else {
        log.info(
            "[AuthWrapper] App lock enabled, but already authenticated. Skipping initial auth prompt.");
        setState(() {
          _isCheckingAuth = false;
        }); // Ensure loading state is off
      }
    } else {
      log.info("[AuthWrapper] App lock disabled, granting access.");
      if (!_isAuthenticated) {
        // Only update state if not already authenticated
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
      } else {
        setState(() {
          _isCheckingAuth = false;
        }); // Ensure loading state is off
      }
    }
  }

  Future<void> _authenticate({bool isRetry = false}) async {
    if (!mounted) return;
    // Prevent multiple simultaneous auth attempts
    if (_isCheckingAuth && !isRetry) {
      log.warning(
          "[AuthWrapper] Authentication already in progress. Ignoring duplicate request.");
      return;
    }
    // Don't prompt if already authenticated unless it's an explicit retry
    if (_isAuthenticated && !isRetry) {
      log.info(
          "[AuthWrapper] Already authenticated. Skipping authentication prompt.");
      setState(() {
        _isCheckingAuth = false;
      }); // Ensure loading state is correct
      return;
    }

    setState(() {
      _isCheckingAuth = true;
    }); // Show loading/locked state
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
        // If auth isn't possible, maybe grant access? Or stay locked? Staying locked for now.
      } else {
        log.info(
            "[AuthWrapper] Device supports auth. Calling local_auth.authenticate...");
        didAuthenticate = await _localAuth.authenticate(
          localizedReason:
              'Please authenticate to access ${AppConstants.appName}',
          options: const AuthenticationOptions(
            stickyAuth: true, // Keep prompt visible
            useErrorDialogs: true, // Use system dialogs for common errors
            biometricOnly: false, // Allow device passcode as well
          ),
        );
        log.info("[AuthWrapper] Authentication result: $didAuthenticate");
      }
    } on PlatformException catch (e, s) {
      errorMsg = "Authentication Error: ${e.message ?? e.code}";
      log.severe("[AuthWrapper] PlatformException during authenticate: $e\n$s");
      if (mounted && e.code != 'auth_in_progress' && e.code != 'user_cancel') {
        // Don't show snackbar for cancellation or overlap
        _showAuthErrorSnackbar(errorMsg);
      }
      // Handle specific errors like 'NotEnrolled', 'LockedOut', etc. if needed
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
          _isCheckingAuth = false; // Done checking
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

// Main Application Widget (Stateless now)
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
