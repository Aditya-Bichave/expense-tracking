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
import 'package:expense_tracker/core/constants/hive_constants.dart'; // Import Hive constants
import 'package:expense_tracker/core/constants/app_constants.dart'; // Import App constants

// Import Models for Hive registration
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';

// Import Blocs
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

final log = SimpleLogger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log.setLevel(Level.INFO, includeCallerInfo: false);
  log.info("Application starting...");

  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(AssetAccountModelAdapter());
    Hive.registerAdapter(IncomeModelAdapter());
    // Use Hive constants for box names
    final expenseBox =
        await Hive.openBox<ExpenseModel>(HiveConstants.expenseBoxName);
    final accountBox =
        await Hive.openBox<AssetAccountModel>(HiveConstants.accountBoxName);
    final incomeBox =
        await Hive.openBox<IncomeModel>(HiveConstants.incomeBoxName);
    final prefs = await SharedPreferences.getInstance();
    await initLocator(
        prefs: prefs,
        expenseBox: expenseBox,
        accountBox: accountBox,
        incomeBox: incomeBox);
    log.info("Hive, SharedPreferences, and Service Locator initialized.");
  } catch (e, s) {
    log.severe("Initialization failed!$e$s");
    runApp(InitializationErrorApp(error: e));
    return;
  }

  runApp(
    // Provide SettingsBloc at the top level
    BlocProvider<SettingsBloc>(
      create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: const AuthWrapper(), // AuthWrapper consumes SettingsBloc
    ),
  );
}

// Simple Widget to show Initialization Error
class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // Use default theme builder before SettingsBloc is ready
    // Access defaults via SettingsState static consts
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
            padding: const EdgeInsets.all(16.0),
            child: Text(
              "Critical Error during App Initialization:\n$error\n\nPlease restart the app or contact support.",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontSize: 16),
            ),
          ),
        ),
      ),
    );
  }
}

// --- AuthWrapper Widget (Reads SettingsBloc, unchanged logic) ---
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
  bool _justAuthenticated = false; // Cooldown flag
  Timer? _authCooldownTimer;
  StreamSubscription? _settingsSubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Wait for the first frame to ensure context is ready for read
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // Check if mounted before accessing context
        _listenForSettingsAndCheckAuth();
      }
    });
    log.info("[AuthWrapper] Initialized and observing lifecycle.");
  }

  void _listenForSettingsAndCheckAuth() {
    // Safely read the bloc using context AFTER initState
    final settingsBloc = context.read<SettingsBloc>();
    if (settingsBloc.state.status == SettingsStatus.loaded ||
        settingsBloc.state.status == SettingsStatus.error) {
      log.info(
          "[AuthWrapper] Settings already loaded/error, checking initial auth state.");
      _checkInitialAuthState(settingsBloc.state);
    } else {
      log.info("[AuthWrapper] Settings not loaded yet, listening to stream.");
      // Only listen if not already loaded/error
      _settingsSubscription = settingsBloc.stream.listen((state) {
        if (state.status == SettingsStatus.loaded ||
            state.status == SettingsStatus.error) {
          log.info(
              "[AuthWrapper] Settings stream emitted ${state.status}. Checking initial auth state.");
          _checkInitialAuthState(state);
          _settingsSubscription?.cancel(); // Cancel after first load/error
          _settingsSubscription = null; // Reset subscription variable
          log.info(
              "[AuthWrapper] Settings subscription cancelled after first load/error.");
        }
      });
    }
  }

  @override
  void dispose() {
    log.info("[AuthWrapper] Disposing.");
    WidgetsBinding.instance.removeObserver(this);
    _authCooldownTimer?.cancel();
    _settingsSubscription?.cancel(); // Cancel if still active
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    log.info("[AuthWrapper] AppLifecycleState changed: $state");
    if (!mounted) return; // Avoid acting on context if disposed

    final bool lockEnabledNow =
        context.read<SettingsBloc>().state.isAppLockEnabled;

    if (state == AppLifecycleState.resumed) {
      _needsAuth = lockEnabledNow; // Update needsAuth flag

      if (lockEnabledNow && !_isAuthenticated && !_justAuthenticated) {
        log.info(
            "[AuthWrapper] App resumed, needs auth and not recently authenticated. Triggering authenticate.");
        _authenticate();
      } else if (lockEnabledNow && _justAuthenticated) {
        log.info(
            "[AuthWrapper] App resumed, just authenticated, skipping immediate auth.");
        // Reset cooldown flag after a delay
        _startAuthCooldown();
      } else if (!lockEnabledNow) {
        log.info("[AuthWrapper] App resumed, lock not enabled.");
        // Ensure authenticated state if lock is off
        if (!_isAuthenticated) {
          setState(() {
            _isAuthenticated = true;
            _isCheckingAuth = false; // Ensure loading stops
          });
        }
      }
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _authCooldownTimer?.cancel(); // Cancel cooldown on pause/inactive
      if (lockEnabledNow) {
        log.info(
            "[AuthWrapper] App paused/inactive, lock enabled. Resetting auth state.");
        // Reset auth state immediately only if lock is enabled
        if (_isAuthenticated || _justAuthenticated) {
          setState(() {
            _isAuthenticated = false;
            _justAuthenticated = false; // Reset cooldown flag too
          });
        }
      } else {
        log.info(
            "[AuthWrapper] App paused/inactive, lock NOT enabled. Auth state remains.");
      }
    }
  }

  Future<void> _checkInitialAuthState(SettingsState settingsState) async {
    if (!mounted) return; // Check if mounted

    final bool appLockEnabled = settingsState.isAppLockEnabled;
    _needsAuth = appLockEnabled;
    log.info("[AuthWrapper] Initial check: App Lock Enabled = $appLockEnabled");

    if (appLockEnabled) {
      log.info(
          "[AuthWrapper] App lock enabled, attempting initial authentication.");
      _authenticate(); // Trigger authentication
    } else {
      log.info("[AuthWrapper] App lock disabled, granting access.");
      setState(() {
        _isAuthenticated = true;
        _isCheckingAuth = false; // Mark auth check complete
      });
    }
  }

  Future<void> _authenticate() async {
    if (!mounted) return; // Check mounted at start
    // Prevent re-entry if already checking
    if (_isCheckingAuth && mounted) {
      // If checking is true BUT isAuthenticated is false, allow re-attempt
      if (_isAuthenticated) return;
    }

    bool didAuthenticate = false;
    String? errorMsg;

    setState(() {
      _isCheckingAuth = true; // Set loading state
    });
    log.info("[AuthWrapper] Starting authentication process...");

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
              'Please authenticate to access ${AppConstants.appName}', // Use constant
          options: const AuthenticationOptions(
              stickyAuth: true, useErrorDialogs: true),
        );
        log.info("[AuthWrapper] Authentication result: $didAuthenticate");
      }
    } on PlatformException catch (e, s) {
      errorMsg = "Authentication Error: ${e.message ?? e.code}";
      log.severe("[AuthWrapper] PlatformException during authenticate:$e$s");
      if (mounted) _showAuthErrorSnackbar(errorMsg);
    } catch (e, s) {
      errorMsg = "An unexpected error occurred during authentication.";
      log.severe("[AuthWrapper] Exception during authenticate$e$s");
      if (mounted) _showAuthErrorSnackbar(errorMsg);
    } finally {
      // Ensure state is updated regardless of success/error
      if (mounted) {
        log.info(
            "[AuthWrapper] Authentication attempt finished. Updating state: Authenticated=$didAuthenticate");
        setState(() {
          _isAuthenticated = didAuthenticate;
          _isCheckingAuth = false; // End loading state
          if (didAuthenticate) {
            _justAuthenticated = true;
            _startAuthCooldown(); // Start cooldown on success
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
          _justAuthenticated = false; // Reset flag after cooldown
          log.info("[AuthWrapper] Auth cooldown finished.");
        });
      }
    });
    log.info("[AuthWrapper] Auth cooldown started.");
  }

  void _showAuthErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
      ));
  }

  @override
  Widget build(BuildContext context) {
    // Watch all relevant settings state changes
    // Use context.select for potentially better performance if only parts are needed
    final settingsState = context.watch<SettingsBloc>().state;
    final currentThemeMode = settingsState.themeMode;
    final currentUiMode = settingsState.uiMode;
    final currentPaletteIdentifier = settingsState.paletteIdentifier;

    log.info(
        "[AuthWrapper] Build: UIMode=$currentUiMode, Palette=$currentPaletteIdentifier, Brightness=$currentThemeMode, NeedsAuth=$_needsAuth, IsAuthenticated=$_isAuthenticated, IsCheckingAuth=$_isCheckingAuth");

    // --- Determine the FINAL theme data using the AppTheme factory ---
    final AppThemeDataPair finalThemeDataPair = AppTheme.buildTheme(
      currentUiMode,
      currentPaletteIdentifier,
    );
    final lightTheme = finalThemeDataPair.light;
    final darkTheme = finalThemeDataPair.dark;
    // --- END Theme Determination Logic ---

    // Initial loading or checking state (before first auth attempt or if lock is on)
    if (_isCheckingAuth && !_isAuthenticated && _needsAuth) {
      log.info(
          "[AuthWrapper UI] Showing Loading Screen (during initial auth check).");
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: currentThemeMode,
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    // Locked state (needs auth but failed or hasn't authenticated yet)
    else if (_needsAuth && !_isAuthenticated) {
      log.info("[AuthWrapper UI] Showing Locked Screen.");
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: currentThemeMode,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_outline,
                      size: 60, color: Theme.of(context).colorScheme.error),
                  const SizedBox(height: 20),
                  const Text('Authentication Required',
                      style: TextStyle(fontSize: 18)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12)),
                    icon: const Icon(Icons.fingerprint),
                    label: const Text('Authenticate / Retry'),
                    // Disable button briefly during auth check
                    onPressed: _isCheckingAuth ? null : _authenticate,
                  )
                ],
              ),
            ),
          ),
        ),
      );
    }
    // Authenticated or lock disabled state
    else {
      log.info(
          "[AuthWrapper UI] Showing Main App (MyApp). Authenticated=$_isAuthenticated, NeedsAuth=$_needsAuth");
      // Provide necessary Blocs *below* the AuthWrapper/MaterialApp if they aren't needed before auth
      // Or keep them here if MyApp structure relies on them immediately
      return MultiBlocProvider(
        providers: [
          // SettingsBloc is already provided above AuthWrapper
          BlocProvider<AccountListBloc>(
            create: (context) =>
                sl<AccountListBloc>()..add(const LoadAccounts()),
            lazy: false, // Load immediately when needed
          ),
          BlocProvider<DashboardBloc>(
            create: (context) =>
                sl<DashboardBloc>()..add(const LoadDashboard()),
            lazy: false,
          ),
          BlocProvider<SummaryBloc>(
            create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
            lazy: false,
          ),
          BlocProvider<ExpenseListBloc>(
            create: (context) =>
                sl<ExpenseListBloc>()..add(const LoadExpenses()),
            lazy: false,
          ),
          BlocProvider<IncomeListBloc>(
            create: (context) => sl<IncomeListBloc>()..add(const LoadIncomes()),
            lazy: false,
          ),
          // AddEdit Blocs are typically created closer to their usage (e.g., in the router or page)
        ],
        child: MyApp(
          lightTheme: lightTheme,
          darkTheme: darkTheme,
          themeMode: currentThemeMode,
        ),
      );
    }
  }
}

// --- MyApp Widget (Consumes themes, sets up Router) ---
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
    // Router can be defined here or globally accessed
    final GoRouter router = AppRouter.router;

    return MaterialApp.router(
      title: AppConstants.appName, // Use constant
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      // Blocs needed globally are provided above MyApp in AuthWrapper
    );
  }
}
