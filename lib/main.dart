import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart'; // Import local_auth
import 'package:shared_preferences/shared_preferences.dart';

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
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive, SharedPreferences, DI
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

  // Wrap MyApp with AuthWrapper and provide SettingsBloc above it
  runApp(
    BlocProvider<SettingsBloc>(
      create: (context) => sl<SettingsBloc>()..add(const LoadSettings()),
      child: const AuthWrapper(),
    ),
  );
}

// --- NEW AuthWrapper Widget ---
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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay initial check slightly to ensure SettingsBloc is ready
    // or handle it via listening to the bloc stream. Listening is better.
    _listenForSettingsAndCheckAuth();
  }

  void _listenForSettingsAndCheckAuth() {
    final settingsBloc = context.read<SettingsBloc>();
    // If settings are already loaded, check auth immediately
    if (settingsBloc.state.status == SettingsStatus.loaded ||
        settingsBloc.state.status == SettingsStatus.error) {
      _checkInitialAuthState(settingsBloc.state);
    } else {
      // Otherwise, wait for the first loaded/error state
      final settingsSubscription = settingsBloc.stream.listen((state) {
        if (state.status == SettingsStatus.loaded ||
            state.status == SettingsStatus.error) {
          _checkInitialAuthState(state);
          // Cancel subscription after first loaded/error state
          // (This assumes settings don't reload often, adjust if needed)
          // settingsSubscription.cancel(); // Be careful with cancelling too early
        }
      });
      // TODO: Consider cancelling the subscription in dispose if needed.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _authCooldownTimer?.cancel();
    // TODO: Cancel settingsSubscription if stored as instance variable
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    debugPrint("[AuthWrapper] AppLifecycleState changed: $state");

    if (state == AppLifecycleState.resumed) {
      // Use the latest state from BLoC to check if auth is needed NOW
      final bool lockEnabledNow =
          context.read<SettingsBloc>().state.isAppLockEnabled;
      _needsAuth = lockEnabledNow; // Update needsAuth flag

      if (lockEnabledNow && !_isAuthenticated && !_justAuthenticated) {
        debugPrint(
            "[AuthWrapper] App resumed, needs auth. Triggering authenticate.");
        _authenticate();
      }
      _authCooldownTimer?.cancel();
      _authCooldownTimer = Timer(const Duration(seconds: 2), () {
        if (mounted) {
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
        debugPrint(
            "[AuthWrapper] App paused/inactive, lock enabled. Resetting auth state.");
        // Reset flags for next resume check
        _isAuthenticated = false;
        _justAuthenticated = false;
        _authCooldownTimer?.cancel();
      }
    }
  }

  Future<void> _checkInitialAuthState(SettingsState settingsState) async {
    // Use the passed state which is confirmed to be loaded or error
    final bool appLockEnabled = settingsState.isAppLockEnabled;
    _needsAuth = appLockEnabled;

    debugPrint(
        "[AuthWrapper] Initial check: App Lock Enabled = $appLockEnabled");

    if (appLockEnabled) {
      // No need to check mount status here as this is called after initState setup
      _authenticate(); // Attempt initial authentication
    } else {
      // No lock enabled, proceed directly
      if (mounted) {
        // Still good practice to check mount before setState
        setState(() {
          _isAuthenticated = true;
          _isCheckingAuth = false;
        });
      }
    }
  }

  Future<void> _authenticate() async {
    if (!mounted) return;

    bool didAuthenticate = false;
    String? errorMsg;
    // Ensure we show loading indicator while authenticate() is running
    if (!_isCheckingAuth) {
      setState(() {
        _isCheckingAuth = true;
      });
    }

    try {
      final bool canAuthenticate = await _localAuth.canCheckBiometrics ||
          await _localAuth.isDeviceSupported();
      if (!canAuthenticate) {
        errorMsg = "Device authentication not available.";
        // Decide UX: Allow access or block? Blocking seems safer for finance app.
        didAuthenticate = false;
        debugPrint(
            "[AuthWrapper] Authentication check failed: Device not supported.");
        // Optionally, disable the lock setting automatically?
        // context.read<SettingsBloc>().add(const UpdateAppLock(false));
      } else {
        debugPrint("[AuthWrapper] Calling local_auth.authenticate...");
        didAuthenticate = await _localAuth.authenticate(
          localizedReason: 'Please authenticate to access Expense Tracker',
          options: const AuthenticationOptions(
            stickyAuth: true, // Keep prompt visible
            // biometricOnly: false // Set to true to ONLY allow biometrics
          ),
        );
        debugPrint("[AuthWrapper] Authentication result: $didAuthenticate");
      }
    } on PlatformException catch (e) {
      errorMsg = "Authentication Error: ${e.code} - ${e.message ?? 'Unknown'}";
      didAuthenticate = false;
      debugPrint(
          "[AuthWrapper] PlatformException during authenticate: ${e.code}");
    } catch (e) {
      errorMsg = "Unexpected Error during auth: $e";
      didAuthenticate = false;
      debugPrint("[AuthWrapper] Exception during authenticate: $e");
    }

    // Update state only if the widget is still mounted after async call
    if (mounted) {
      setState(() {
        _isAuthenticated = didAuthenticate;
        _isCheckingAuth = false; // Done checking/attempting
        _justAuthenticated = didAuthenticate;
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
      } else if (errorMsg != null) {
        // Show error message if authentication failed
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(errorMsg),
              backgroundColor: Theme.of(context).colorScheme.error,
              duration: const Duration(seconds: 5), // Show longer for errors
            ),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Read themeMode directly for Locked/Loading screens
    final currentThemeMode = context.watch<SettingsBloc>().state.themeMode;

    if (_isCheckingAuth && !_isAuthenticated) {
      // Show loading/splash screen
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: currentThemeMode,
        home: const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    } else if (_needsAuth && !_isAuthenticated) {
      // Show locked screen
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: currentThemeMode,
        home: Scaffold(
          body: Center(
            child: Padding(
              // Add padding
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
                    onPressed: _authenticate, // Call authenticate again
                  )
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      // Show main app
      return const MyApp();
    }
  }
}

// --- Original MyApp Widget (No changes needed here from previous step) ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final GoRouter router = AppRouter.router;

    return MultiBlocProvider(
      providers: [
        // SettingsBloc is already provided above AuthWrapper
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
        title: 'Expense Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        // Watch themeMode for live updates within the authenticated app
        themeMode: context.watch<SettingsBloc>().state.themeMode,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
