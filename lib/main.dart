import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart'; // Import local_auth
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logger/simple_logger.dart'; // Import Logger

// Import Core dependencies
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/router.dart';

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
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart'; // Import UIMode

final log = SimpleLogger(); // Create logger instance

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure Logger (Optional: Set level, etc.)
  log.setLevel(Level.INFO,
      includeCallerInfo: false); // Changed to INFO for more detail
  log.info("Application starting...");

  // Initialize Hive, SharedPreferences, DI
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(ExpenseModelAdapter());
    Hive.registerAdapter(AssetAccountModelAdapter());
    Hive.registerAdapter(IncomeModelAdapter());
    final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
    final accountBox = await Hive.openBox<AssetAccountModel>('asset_accounts');
    final incomeBox = await Hive.openBox<IncomeModel>('incomes');
    final prefs = await SharedPreferences.getInstance();
    await initLocator(
        prefs: prefs,
        expenseBox: expenseBox,
        accountBox: accountBox,
        incomeBox: incomeBox);
    log.info("Hive, SharedPreferences, and Service Locator initialized.");
  } catch (e, s) {
    log.severe("Initialization failed!$e$s");
    // Optionally show an error message to the user before exiting or failing gracefully
    runApp(InitializationErrorApp(error: e));
    return;
  }

  // Wrap MyApp with AuthWrapper and provide SettingsBloc above it
  runApp(
    BlocProvider<SettingsBloc>(
      create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: const AuthWrapper(),
    ),
  );
}

// Simple Widget to show Initialization Error
class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: AppTheme.getThemeDataByIdentifier(AppTheme.elementalThemeId)
          .light, // Use default
      darkTheme:
          AppTheme.getThemeDataByIdentifier(AppTheme.elementalThemeId).dark,
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

// --- AuthWrapper Widget ---
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

// --- Mixin WidgetsBindingObserver ---
class _AuthWrapperState extends State<AuthWrapper> with WidgetsBindingObserver {
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isCheckingAuth = true; // Start checking immediately
  bool _needsAuth = false;
  bool _isAuthenticated = false;
  bool _justAuthenticated = false;
  Timer? _authCooldownTimer;
  StreamSubscription? _settingsSubscription; // Store subscription

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenForSettingsAndCheckAuth();
    log.info("[AuthWrapper] Initialized and observing lifecycle.");
  }

  void _listenForSettingsAndCheckAuth() {
    final settingsBloc = context.read<SettingsBloc>();
    // If settings are already loaded, check auth immediately
    if (settingsBloc.state.status == SettingsStatus.loaded ||
        settingsBloc.state.status == SettingsStatus.error) {
      log.info(
          "[AuthWrapper] Settings already loaded/error, checking initial auth state.");
      _checkInitialAuthState(settingsBloc.state);
    } else {
      log.info("[AuthWrapper] Settings not loaded yet, listening to stream.");
      // Otherwise, wait for the first loaded/error state
      _settingsSubscription = settingsBloc.stream.listen((state) {
        if (state.status == SettingsStatus.loaded ||
            state.status == SettingsStatus.error) {
          log.info(
              "[AuthWrapper] Settings stream emitted ${state.status}. Checking initial auth state.");
          _checkInitialAuthState(state);
          // Cancel subscription after first loaded/error state
          _settingsSubscription?.cancel();
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
    _settingsSubscription?.cancel(); // Cancel subscription if active
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    log.info("[AuthWrapper] AppLifecycleState changed: $state");

    if (state == AppLifecycleState.resumed) {
      // Use the latest state from BLoC to check if auth is needed NOW
      final bool lockEnabledNow =
          context.read<SettingsBloc>().state.isAppLockEnabled;
      _needsAuth = lockEnabledNow; // Update needsAuth flag

      if (lockEnabledNow && !_isAuthenticated && !_justAuthenticated) {
        log.info(
            "[AuthWrapper] App resumed, needs auth. Triggering authenticate.");
        _authenticate();
      } else if (lockEnabledNow && _justAuthenticated) {
        log.info(
            "[AuthWrapper] App resumed, just authenticated, skipping immediate auth.");
      } else if (!lockEnabledNow) {
        log.info("[AuthWrapper] App resumed, lock not enabled.");
        // Ensure user can access if lock was disabled while app was paused
        if (!_isAuthenticated && mounted) {
          setState(() {
            _isAuthenticated = true;
            _isCheckingAuth = false;
          });
        }
      }

      // Reset justAuthenticated flag after cooldown
      _authCooldownTimer?.cancel();
      _authCooldownTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
          // log.info("[AuthWrapper] Auth cooldown finished, resetting _justAuthenticated.");
          setState(() {
            _justAuthenticated = false;
          });
        }
      });
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // Use the latest state from BLoC
      final bool lockEnabledNow =
          context.read<SettingsBloc>().state.isAppLockEnabled;
      if (lockEnabledNow) {
        log.info(
            "[AuthWrapper] App paused/inactive, lock enabled. Resetting auth state.");
        // Reset flags for next resume check
        if (mounted) {
          // Check mount before setState
          setState(() {
            _isAuthenticated = false;
            _justAuthenticated = false;
          });
        } else {
          // If not mounted, just update variables
          _isAuthenticated = false;
          _justAuthenticated = false;
        }
        _authCooldownTimer?.cancel();
      } else {
        log.info("[AuthWrapper] App paused/inactive, lock NOT enabled.");
      }
    }
  }

  Future<void> _checkInitialAuthState(SettingsState settingsState) async {
    final bool appLockEnabled = settingsState.isAppLockEnabled;
    _needsAuth = appLockEnabled;

    log.info("[AuthWrapper] Initial check: App Lock Enabled = $appLockEnabled");

    if (appLockEnabled) {
      log.info(
          "[AuthWrapper] App lock enabled, attempting initial authentication.");
      _authenticate(); // Attempt initial authentication
    } else {
      // No lock enabled, proceed directly
      if (mounted) {
        log.info("[AuthWrapper] App lock disabled, granting access.");
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
      } else {
        log.warning(
            "[AuthWrapper] _checkInitialAuthState called but widget not mounted.");
      }
    }
  }

  Future<void> _authenticate() async {
    if (!mounted) {
      log.warning("[AuthWrapper] _authenticate called but widget not mounted.");
      return;
    }

    // Prevent multiple auth prompts simultaneously
    if (_isCheckingAuth) {
      log.info("[AuthWrapper] Authentication already in progress, skipping.");
      return;
    }

    bool didAuthenticate = false;
    String? errorMsg;
    // Ensure we show loading indicator while authenticate() is running
    setState(() {
      _isCheckingAuth = true;
    });
    log.info("[AuthWrapper] Starting authentication process...");

    try {
      log.info("[AuthWrapper] Checking device support for biometrics/auth...");
      final bool canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        errorMsg = "Device authentication not available or not set up.";
        didAuthenticate =
            false; // Block access if auth is required but unavailable
        log.warning(
            "[AuthWrapper] Authentication check failed: Device not supported or auth not set up.");
        // Suggest disabling lock?
        if (mounted) {
          _showAuthErrorSnackbar(errorMsg);
          // Keep user on locked screen, they need to manually authenticate/retry
        }
      } else {
        log.info(
            "[AuthWrapper] Device supports auth. Calling local_auth.authenticate...");
        didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access ${AppTheme.appName}',
          options: const AuthenticationOptions(
            stickyAuth: true, // Keep prompt visible
            useErrorDialogs: true, // Use system dialogs for errors like lockout
            // biometricOnly: false // Allow passcode/pattern too
          ),
        );
        log.info("[AuthWrapper] Authentication result: $didAuthenticate");
      }
    } on PlatformException catch (e, s) {
      errorMsg = "Authentication Error: ${e.message ?? e.code}";
      didAuthenticate = false;
      log.severe("[AuthWrapper] PlatformException during authenticate:$e$s");
      if (mounted) _showAuthErrorSnackbar(errorMsg);
    } catch (e, s) {
      errorMsg = "An unexpected error occurred during authentication.";
      didAuthenticate = false;
      log.severe("[AuthWrapper] Exception during authenticate$e$s");
      if (mounted) _showAuthErrorSnackbar(errorMsg);
    }

    // --- State Update ---
    if (mounted) {
      log.info(
          "[AuthWrapper] Authentication attempt finished. Updating state: Authenticated=$didAuthenticate");
      setState(() {
        _isAuthenticated = didAuthenticate;
        _isCheckingAuth = false; // Done checking/attempting
        _justAuthenticated = didAuthenticate; // Mark as just authenticated
      });

      if (didAuthenticate) {
        // Reset flag after a short delay
        _authCooldownTimer?.cancel();
        _authCooldownTimer = Timer(const Duration(seconds: 2), () {
          if (mounted) {
            setState(() {
              _justAuthenticated = false;
            });
          }
        });
      }
      // Error message is shown via _showAuthErrorSnackbar inside catch blocks
    } else {
      log.warning(
          "[AuthWrapper] Authentication finished, but widget not mounted. State not updated.");
    }
  }

  void _showAuthErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 5), // Show longer for errors
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // Watch all relevant settings state
    final settingsState = context.watch<SettingsBloc>().state;
    final currentThemeMode = settingsState.themeMode;
    final currentUIMode = settingsState.uiMode;
    final selectedColorThemeIdentifier = settingsState.selectedThemeIdentifier;
    final isAppLockEnabled =
        settingsState.isAppLockEnabled; // Needed for logic below

    _needsAuth = isAppLockEnabled; // Update needsAuth based on current state

    // --- Determine the FINAL theme data based on UI Mode ---
    final AppThemeData finalThemeData;
    // Select the base theme builder based on the UI Mode
    switch (currentUIMode) {
      case UIMode.quantum:
        // TODO: Choose between Quantum themes (e.g., mono vs terminal) based on selectedColorThemeIdentifier if needed
        finalThemeData =
            AppTheme.getThemeDataByIdentifier(AppTheme.quantumMonoThemeId);
        break;
      case UIMode.aether:
        // TODO: Choose between Aether sub-themes based on selectedColorThemeIdentifier if needed
        finalThemeData =
            AppTheme.getThemeDataByIdentifier(AppTheme.aetherGardenThemeId);
        break;
      case UIMode.elemental:
      default:
        // Elemental uses the selected color variant from settings
        finalThemeData =
            AppTheme.getThemeDataByIdentifier(selectedColorThemeIdentifier);
        break;
    }
    // --- END Theme Determination Logic ---

    log.info(
        "[AuthWrapper] Build method running. Status: NeedsAuth=$_needsAuth, IsAuthenticated=$_isAuthenticated, IsCheckingAuth=$_isCheckingAuth, UIMode=$currentUIMode, ThemeID=$selectedColorThemeIdentifier");

    // Determine light/dark themes based on the FINAL theme data
    final lightTheme = finalThemeData.light;
    final darkTheme = finalThemeData.dark;

    if (_isCheckingAuth && !_isAuthenticated && _needsAuth) {
      // Only show loading if auth is needed and not done
      // Show loading/splash screen
      log.info("[AuthWrapper UI] Showing Loading Screen (Auth Check).");
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: currentThemeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (_needsAuth && !_isAuthenticated) {
      // Show locked screen
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
                    onPressed: _isCheckingAuth
                        ? null
                        : _authenticate, // Disable while checking
                  )
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Show main app (either lock disabled or successfully authenticated)
      if (!_isAuthenticated && !_needsAuth) {
        // Update state if lock was just disabled
        log.info(
            "[AuthWrapper] Lock disabled, ensuring isAuthenticated is true.");
        _isAuthenticated = true;
      }
      log.info(
          "[AuthWrapper UI] Showing Main App (MyApp). Authenticated: $_isAuthenticated");
      // Pass the final decided theme data down to MyApp
      return MyApp(
        lightTheme: lightTheme,
        darkTheme: darkTheme,
        themeMode: currentThemeMode,
      );
    }
  }
}

// --- MyApp Widget (Modified for Theme Injection) ---
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

    // SettingsBloc is provided above AuthWrapper, so it's available here via context.read or BlocProvider.value
    // No need to watch SettingsBloc *again* here for theme, as it's passed down.

    return MultiBlocProvider(
      providers: [
        // SettingsBloc is already provided above AuthWrapper
        // Get other Blocs from Service Locator (sl)
        BlocProvider<AccountListBloc>(
          create: (context) => sl<AccountListBloc>()..add(const LoadAccounts()),
        ),
        BlocProvider<DashboardBloc>(
          create: (context) => sl<DashboardBloc>()..add(const LoadDashboard()),
        ),
        BlocProvider<SummaryBloc>(
          create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
        ),
        BlocProvider<ExpenseListBloc>(
          create: (context) => sl<ExpenseListBloc>()..add(const LoadExpenses()),
        ),
        BlocProvider<IncomeListBloc>(
          create: (context) => sl<IncomeListBloc>()..add(const LoadIncomes()),
        ),
      ],
      child: MaterialApp.router(
        title: AppTheme.appName,
        // Apply the THEMES PASSED DOWN from AuthWrapper
        theme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
