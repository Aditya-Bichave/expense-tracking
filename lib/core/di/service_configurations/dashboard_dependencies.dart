// lib/core/di/service_configurations/dashboard_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/dashboard/domain/usecases/get_financial_overview.dart';
import 'package:expense_tracker/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class DashboardDependencies {
  static void register() {
    // Use Cases (Depends on Account, Income, Expense Repos)
    sl.registerLazySingleton(
      () => GetFinancialOverviewUseCase(
        accountRepository: sl(),
        incomeRepository: sl(),
        expenseRepository: sl(),
        budgetRepository: sl(),
        goalRepository: sl(),
      ),
    );
    // Bloc
    sl.registerFactory(
      () => DashboardBloc(
        getFinancialOverviewUseCase: sl(),
        dataChangeStream: sl<Stream<DataChangedEvent>>(),
      ),
    );
  }
}
