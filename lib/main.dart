import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_event.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_state.dart';
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/theme/app_mode_theme.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_event.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management_bloc.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management_event.dart';
import 'package:expense_tracker/features/budget/presentation/bloc/budget_list_bloc.dart';
import 'package:expense_tracker/features/budget/presentation/bloc/budget_list_event.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list_bloc.dart';
import 'package:expense_tracker/features/goals/presentation/bloc/goal_list_event.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_event.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list_bloc.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list_event.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/core/utils/bloc_observer.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_event.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/services/deep_link_service.dart';
import 'package:expense_tracker/core/bloc/deep_link_bloc.dart';
import 'package:expense_tracker/core/bloc/deep_link_event.dart';

export 'package:expense_tracker/core/utils/logger.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await AppInitializer.init();
      final args = await DeepLinkService.getInitialLink();
      runApp(App(args: args));
    } catch (e, stack) {
      log.severe('Initialization failed', e, stack);
      runApp(InitializationErrorApp(error: e));
    }
  }, (error, stack) {
    log.severe('Unhandled error caught by zone', error, stack);
  });
}

class AppInitializer {
  static Future<void> init() async {
    Bloc.observer = AppBlocObserver();
    await initDependencies();
  }
}

class App extends StatelessWidget {
  final DeepLinkArgs? args;
  const App({super.key, this.args});

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
          create: (context) =>
              sl<AccountListBloc>()..add(const LoadAccounts()),
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
    ),
  );
}

class InitializationErrorApp extends StatefulWidget {
  final Object error;
  final ThemeData? theme; // Allow injecting theme for testing

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
                      "A critical error occurred during startup:\n\n${widget.error.toString()}\n\nPlease restart the app. If the problem persists, contact support or check logs.",
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
                      if (_isResetting)
                        const CircularProgressIndicator()
                      else
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
