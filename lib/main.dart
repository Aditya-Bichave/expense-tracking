import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Needed for DI init

// Import Core dependencies
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import initLocator and sl
import 'package:expense_tracker/router.dart'; // Import AppRouter

// Import Models for Hive registration
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';

// Import Blocs needed globally or for initial load
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
// --- Settings Bloc Import ---
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
// --- End Settings Bloc Import ---

Future<void> main() async {
  // Ensure main is async
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter()); // typeId: 0
  Hive.registerAdapter(AssetAccountModelAdapter()); // typeId: 1
  Hive.registerAdapter(IncomeModelAdapter()); // typeId: 2

  // Open Hive boxes
  // These need to be available before DI initialization if sources depend on them
  final expenseBox = await Hive.openBox<ExpenseModel>('expenses');
  final accountBox = await Hive.openBox<AssetAccountModel>('asset_accounts');
  final incomeBox = await Hive.openBox<IncomeModel>('incomes');

  // Also need SharedPreferences instance for SettingsDataSource
  final prefs = await SharedPreferences.getInstance();

  // Initialize Service Locator (Dependency Injection)
  // Pass required instances like SharedPreferences and Hive Boxes
  await initLocator(
      prefs: prefs,
      expenseBox: expenseBox,
      accountBox: accountBox,
      incomeBox: incomeBox);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the GoRouter instance
    final GoRouter router = AppRouter.router;

    return MultiBlocProvider(
      providers: [
        // Provide SettingsBloc globally first - needed for ThemeMode
        BlocProvider<SettingsBloc>(
          create: (context) => sl<SettingsBloc>()
            ..add(const LoadSettings()), // Load initial settings
        ),
        // Provide other Blocs that need to be globally accessible or loaded initially
        BlocProvider<AccountListBloc>(
          create: (context) =>
              sl<AccountListBloc>()..add(const LoadAccounts()), // Initial load
        ),
        BlocProvider<DashboardBloc>(
          create: (context) =>
              sl<DashboardBloc>()..add(const LoadDashboard()), // Initial load
        ),
        BlocProvider<SummaryBloc>(
          create: (context) =>
              sl<SummaryBloc>()..add(const LoadSummary()), // Initial load
        ),
        BlocProvider<ExpenseListBloc>(
          create: (context) =>
              sl<ExpenseListBloc>()..add(const LoadExpenses()), // Initial load
        ),
        BlocProvider<IncomeListBloc>(
          create: (context) =>
              sl<IncomeListBloc>()..add(const LoadIncomes()), // Initial load
        ),
        // Add other global Blocs if needed
      ],
      // Use BlocBuilder to dynamically set the theme based on SettingsBloc state
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          return MaterialApp.router(
            title: 'Expense Tracker',
            theme: AppTheme.lightTheme, // Your light theme definition
            darkTheme: AppTheme.darkTheme, // Your dark theme definition
            themeMode: settingsState.themeMode, // Apply theme from SettingsBloc
            debugShowCheckedModeBanner: false,
            // Configure router
            routerConfig: router,
          );
        },
      ),
    );
  }
}
