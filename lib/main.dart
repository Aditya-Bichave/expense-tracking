import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

// Import Core dependencies
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/core/di/service_locator.dart'; // Import initLocator
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(ExpenseModelAdapter()); // typeId: 0
  Hive.registerAdapter(AssetAccountModelAdapter()); // typeId: 1
  Hive.registerAdapter(IncomeModelAdapter()); // typeId: 2

  // Open Hive boxes
  await Hive.openBox<ExpenseModel>('expenses');
  await Hive.openBox<AssetAccountModel>('asset_accounts');
  await Hive.openBox<IncomeModel>('incomes');

  // Initialize Service Locator (Dependency Injection)
  // *** FIX: Use the correct function name 'initLocator' ***
  await initLocator();
  // ******************************************************

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
        // Provide Blocs that need to be globally accessible or loaded initially
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
      child: MaterialApp.router(
        title: 'Expense Tracker',
        theme: AppTheme.lightTheme, // Use your theme
        darkTheme: AppTheme.darkTheme, // Optional dark theme
        themeMode: ThemeMode.system, // Or ThemeMode.light / ThemeMode.dark
        debugShowCheckedModeBanner: false,
        // Configure router
        routerConfig: router,
      ),
    );
  }
}
