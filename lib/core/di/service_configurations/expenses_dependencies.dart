import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source.dart';
import 'package:expense_tracker/features/expenses/data/datasources/expense_local_data_source_proxy.dart';
import 'package:expense_tracker/features/expenses/data/repositories/expense_repository_impl.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/add_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/delete_expense.dart';
import 'package:expense_tracker/features/expenses/domain/usecases/update_expense.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // Import SupabaseClient

class ExpensesDependencies {
  static void register() {
    // Data Source (Proxy that wraps the real one)
    sl.registerLazySingleton<ExpenseLocalDataSource>(
      () => DemoAwareExpenseDataSource(
        hiveDataSource: sl<HiveExpenseLocalDataSource>(),
        demoModeService: sl<DemoModeService>(),
      ),
    );

    sl.registerLazySingleton<ExpenseRepository>(
      () => ExpenseRepositoryImpl(
        localDataSource: sl(),
        categoryRepository: sl(),
        supabaseClient: sl<SupabaseClient>(), // Inject SupabaseClient
      ),
    );

    // Domain
    sl.registerLazySingleton(() => AddExpenseUseCase(sl()));
    sl.registerLazySingleton(() => UpdateExpenseUseCase(sl()));
    sl.registerLazySingleton(() => DeleteExpenseUseCase(sl()));
  }
}
