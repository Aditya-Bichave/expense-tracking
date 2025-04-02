import 'package:expense_tracker/features/accounts/data/models/asset_account_model.dart';
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:expense_tracker/core/di/service_locator.dart' as di;
import 'package:expense_tracker/core/theme/app_theme.dart';
import 'package:expense_tracker/router.dart';
import 'package:expense_tracker/features/accounts/presentation/bloc/account_list/account_list_bloc.dart';
import 'package:expense_tracker/features/expenses/presentation/bloc/expense_list/expense_list_bloc.dart';
import 'package:expense_tracker/features/income/presentation/bloc/income_list/income_list_bloc.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Hive
  await Hive.initFlutter();

  // 2. Register ALL Hive Adapters BEFORE opening boxes or initializing DI
  // Ensure these typeIds are unique and match your model annotations
  Hive.registerAdapter(ExpenseModelAdapter()); // typeId: 0 (from model)
  Hive.registerAdapter(AssetAccountModelAdapter()); // typeId: 1 (from model)
  Hive.registerAdapter(IncomeModelAdapter()); // typeId: 2 (from model)
  // Add adapters for any other HiveObject models here

  // 3. Initialize dependency injection (which likely opens boxes)
  await di.initDI(); // Call your service locator setup function

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use MultiBlocProvider to make Blocs available globally
    // These Blocs will manage the data lists used across different tabs/pages.
    return MultiBlocProvider(
      providers: [
        BlocProvider<AccountListBloc>(
          // Create and trigger initial load
          create: (context) => di.sl<AccountListBloc>()..add(LoadAccounts()),
          lazy: false, // Load immediately
        ),
        BlocProvider<ExpenseListBloc>(
          create: (context) => di.sl<ExpenseListBloc>()..add(LoadExpenses()),
          lazy: false,
        ),
        BlocProvider<IncomeListBloc>(
          create: (context) => di.sl<IncomeListBloc>()..add(LoadIncomes()),
          lazy: false,
        ),
        BlocProvider<DashboardBloc>(
          // DashboardBloc depends on the others, ensure they load first or handle dependencies
          create: (context) =>
              di.sl<DashboardBloc>()..add(const LoadDashboard()),
          lazy: false,
        ),
        BlocProvider<SummaryBloc>(
          // SummaryBloc depends on ExpenseListBloc
          create: (context) => di.sl<SummaryBloc>()..add(const LoadSummary()),
          lazy: false,
        ),
        // AddEdit Blocs should typically be provided locally on their respective pages,
        // unless you need to maintain their state across navigation (less common).
      ],
      child: MaterialApp.router(
        title: 'Expense Tracker',
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Or ThemeMode.light / ThemeMode.dark
        debugShowCheckedModeBanner: false,
        routerConfig: AppRouter.router, // Use the router configuration
      ),
    );
  }
}
