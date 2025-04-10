// lib/core/di/service_configurations/report_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/reports/data/repositories/report_repository_impl.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
// Use Cases
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_category_report.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_spending_time_report.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_income_expense_report.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_budget_performance_report.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_goal_progress_report.dart';
// Blocs
import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_category_report/spending_category_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/presentation/bloc/goal_progress_report/goal_progress_report_bloc.dart';
// --- ADDED Export Helper ---
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
// --- ADDED Required UseCases for Filter Bloc ---
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/accounts/domain/usecases/get_asset_accounts.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/goals/domain/usecases/get_goals.dart';

class ReportDependencies {
  static void register() {
    // --- Repository ---
    sl.registerLazySingleton<ReportRepository>(() => ReportRepositoryImpl(
          expenseRepository: sl(),
          incomeRepository: sl(),
          categoryRepository: sl(),
          accountRepository: sl(),
          budgetRepository: sl(),
          goalRepository: sl(),
          goalContributionRepository: sl(),
        ));

    // --- Use Cases ---
    sl.registerLazySingleton(() => GetSpendingCategoryReportUseCase(sl()));
    sl.registerLazySingleton(() => GetSpendingTimeReportUseCase(sl()));
    sl.registerLazySingleton(() => GetIncomeExpenseReportUseCase(sl()));
    sl.registerLazySingleton(() => GetBudgetPerformanceReportUseCase(sl()));
    sl.registerLazySingleton(() => GetGoalProgressReportUseCase(sl()));

    // --- Helpers ---
    sl.registerLazySingleton<CsvExportHelper>(() => CsvExportHelper());

    // --- Blocs ---
    // Shared filter bloc - Singleton
    sl.registerLazySingleton<ReportFilterBloc>(() => ReportFilterBloc(
          // --- FINAL FIX: Use parameter names from the Bloc's constructor ---
          categoryRepository: sl<
              GetCategoriesUseCase>(), // Parameter name is 'categoryRepository'
          accountRepository: sl<
              GetAssetAccountsUseCase>(), // Parameter name is 'accountRepository'
          budgetRepository:
              sl<GetBudgetsUseCase>(), // Parameter name is 'budgetRepository'
          goalRepository:
              sl<GetGoalsUseCase>(), // Parameter name is 'goalRepository'
          // --- END FIX ---
        ));

    // Individual report Blocs (depend on filter bloc stream) - Factory
    sl.registerFactory<SpendingCategoryReportBloc>(() =>
        SpendingCategoryReportBloc(
            getSpendingCategoryReportUseCase: sl(), reportFilterBloc: sl()));
    sl.registerFactory<SpendingTimeReportBloc>(() => SpendingTimeReportBloc(
        getSpendingTimeReportUseCase: sl(), reportFilterBloc: sl()));
    sl.registerFactory<IncomeExpenseReportBloc>(() => IncomeExpenseReportBloc(
        getIncomeExpenseReportUseCase: sl(), reportFilterBloc: sl()));
    sl.registerFactory<BudgetPerformanceReportBloc>(() =>
        BudgetPerformanceReportBloc(
            getBudgetPerformanceReportUseCase: sl(), reportFilterBloc: sl()));
    sl.registerFactory<GoalProgressReportBloc>(() => GoalProgressReportBloc(
        getGoalProgressReportUseCase: sl(), reportFilterBloc: sl()));
  }
}
