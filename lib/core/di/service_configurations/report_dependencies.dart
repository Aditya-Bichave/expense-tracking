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
import 'package:expense_tracker/features/accounts/domain/usecases/get_liabilities.dart';
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
          transactionRepository: sl(),
        ));

    // --- Use Cases ---
    sl.registerLazySingleton(() => GetSpendingCategoryReportUseCase(sl()));
    sl.registerLazySingleton(() => GetSpendingTimeReportUseCase(sl()));
    sl.registerLazySingleton(() => GetIncomeExpenseReportUseCase(sl()));
    sl.registerLazySingleton(() => GetBudgetPerformanceReportUseCase(sl()));
    sl.registerLazySingleton(() => GetGoalProgressReportUseCase(sl()));

    // --- Helpers ---
    sl.registerLazySingleton<CsvExportHelper>(
        () => CsvExportHelper(downloaderService: sl()));

    // --- Blocs ---
    // Filter bloc - Factory (new instance per report page)
    sl.registerFactory<ReportFilterBloc>(() => ReportFilterBloc(
          categoryRepository: sl<GetCategoriesUseCase>(),
          accountRepository: sl<GetAssetAccountsUseCase>(),
          liabilityRepository: sl<GetLiabilitiesUseCase>(),
          budgetRepository: sl<GetBudgetsUseCase>(),
          goalRepository: sl<GetGoalsUseCase>(),
        ));

    // Individual report Blocs require an external ReportFilterBloc
    sl.registerFactoryParam<SpendingCategoryReportBloc, ReportFilterBloc, void>(
        (filterBloc, _) => SpendingCategoryReportBloc(
            getSpendingCategoryReportUseCase: sl(),
            reportFilterBloc: filterBloc));
    sl.registerFactoryParam<SpendingTimeReportBloc, ReportFilterBloc, void>(
        (filterBloc, _) => SpendingTimeReportBloc(
            getSpendingTimeReportUseCase: sl(), reportFilterBloc: filterBloc));
    sl.registerFactoryParam<IncomeExpenseReportBloc, ReportFilterBloc, void>(
        (filterBloc, _) => IncomeExpenseReportBloc(
            getIncomeExpenseReportUseCase: sl(), reportFilterBloc: filterBloc));
    sl.registerFactoryParam<BudgetPerformanceReportBloc, ReportFilterBloc,
            void>(
        (filterBloc, _) => BudgetPerformanceReportBloc(
            getBudgetPerformanceReportUseCase: sl(),
            reportFilterBloc: filterBloc));
    sl.registerFactoryParam<GoalProgressReportBloc, ReportFilterBloc, void>(
        (filterBloc, _) => GoalProgressReportBloc(
            getGoalProgressReportUseCase: sl(), reportFilterBloc: filterBloc));
  }
}
