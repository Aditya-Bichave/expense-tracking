// lib/core/di/service_configurations/income_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source.dart';
import 'package:expense_tracker/features/income/data/datasources/income_local_data_source_proxy.dart'; // Import proxy
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/data/repositories/income_repository_impl.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/income/domain/usecases/add_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/delete_income.dart';
import 'package:expense_tracker/features/income/domain/usecases/update_income.dart';
import 'package:hive_ce/hive.dart'; // Keep for HiveIncomeLocalDataSource

class IncomeDependencies {
  static void register() {
    // --- MODIFIED: Register Proxy ---
    sl.registerLazySingleton<IncomeLocalDataSource>(
      () => DemoAwareIncomeDataSource(
        hiveDataSource: sl<HiveIncomeLocalDataSource>(), // Get real DS
        demoModeService: sl<DemoModeService>(),
      ),
    );
    // --- END MODIFIED ---

    sl.registerLazySingleton<IncomeRepository>(
      () => IncomeRepositoryImpl(
        localDataSource: sl(),
        categoryRepository: sl(),
      ),
    );
    // Domain
    sl.registerLazySingleton(() => AddIncomeUseCase(sl()));
    sl.registerLazySingleton(() => UpdateIncomeUseCase(sl()));
    sl.registerLazySingleton(() => DeleteIncomeUseCase(sl()));
  }
}
