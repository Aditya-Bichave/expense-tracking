// lib/core/di/service_configuration/analytics_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/analytics/domain/usecases/get_expense_summary.dart';
import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';

class AnalyticsDependencies {
  static void register() {
    // Use Cases (Depends on Expense Repo)
    sl.registerLazySingleton(() => GetExpenseSummaryUseCase(sl()));
    // Bloc
    sl.registerFactory(() => SummaryBloc(
          getExpenseSummaryUseCase: sl(),
          dataChangeStream: sl<Stream<DataChangedEvent>>(),
        ));
  }
}
