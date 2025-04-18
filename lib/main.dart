// lib/main.dart
import 'dart:async';
import 'package:expense_tracker/core/constants/app_constants.dart';
import 'package:expense_tracker/core/constants/hive_constants.dart';
import 'package:expense_tracker/core/constants/route_names.dart'; // Added
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
import 'package:expense_tracker/features/settings/presentation/bloc/data_management/data_management_bloc.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/router.dart';
// Removed InitialSetupScreen import, handled by router
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
// Removed local_auth import, handled by Settings page
import 'package:shared_preferences/shared_preferences.dart';
import 'package:simple_logger/simple_logger.dart';

final log = SimpleLogger();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  log.setLevel(Level.INFO, includeCallerInfo: false);
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
    Hive.registerAdapter(GoalModelAdapter());
    Hive.registerAdapter(GoalContributionModelAdapter());

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
    final goalBox = await Hive.openBox<GoalModel>(HiveConstants.goalBoxName);
    final contributionBox = await Hive.openBox<GoalContributionModel>(
        HiveConstants.goalContributionBoxName);
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
      goalBox: goalBox,
      contributionBox: contributionBox,
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
        lazy: true, // Can lazy load these data blocs
      ),
      BlocProvider<TransactionListBloc>(
        create: (context) =>
            sl<TransactionListBloc>()..add(const LoadTransactions()),
        lazy: true,
      ),
      BlocProvider<CategoryManagementBloc>(
        create: (context) =>
            sl<CategoryManagementBloc>()..add(const LoadCategories()),
        lazy: true,
      ),
      BlocProvider<BudgetListBloc>(
        create: (context) => sl<BudgetListBloc>()..add(const LoadBudgets()),
        lazy: true,
      ),
      BlocProvider<GoalListBloc>(
        create: (context) => sl<GoalListBloc>()..add(const LoadGoals()),
        lazy: true,
      ),
      BlocProvider<DashboardBloc>(
        create: (context) => sl<DashboardBloc>()..add(const LoadDashboard()),
        lazy: true,
      ),
      BlocProvider<SummaryBloc>(
        create: (context) => sl<SummaryBloc>()..add(const LoadSummary()),
        lazy: true,
      ),
    ],
    child: const MyApp(), // Use MyApp directly, router handles initial screen
  ));
}

class InitializationErrorApp extends StatelessWidget {
  final Object error;
  const InitializationErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    // Provide default theme data even if settings failed
    final defaultThemePair = AppTheme.buildTheme(
        SettingsState.defaultUIMode, SettingsState.defaultPaletteIdentifier);

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

// --- MyApp (Consumes Router) ---
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch SettingsBloc for theme changes
    final settingsState = context.watch<SettingsBloc>().state;
    final themeMode = settingsState.themeMode;
    final uiMode = settingsState.uiMode;
    final paletteId = settingsState.paletteIdentifier;

    // Rebuild theme data whenever settings change
    final themeDataPair = AppTheme.buildTheme(uiMode, paletteId);

    return MaterialApp.router(
      title: AppConstants.appName,
      theme: themeDataPair.light,
      darkTheme: themeDataPair.dark,
      themeMode: themeMode,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router, // Use the configured router
    );
  }
}
