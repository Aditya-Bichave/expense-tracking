// lib/core/di/service_configurations/budget_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source_proxy.dart'; // Import proxy
import 'package:expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart'; // Dependency
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart'; // Dependency
import 'package:uuid/uuid.dart'; // Dependency
import 'dart:async'; // Needed for Stream

class BudgetDependencies {
  static void register() {
    // --- MODIFIED: Register Proxy ---
    sl.registerLazySingleton<BudgetLocalDataSource>(
      () => DemoAwareBudgetDataSource(
        hiveDataSource: sl<HiveBudgetLocalDataSource>(), // Get real DS
        demoModeService: sl<DemoModeService>(),
      ),
    );
    // --- END MODIFIED ---

    // Repository (Depends on Expense Repo)
    sl.registerLazySingleton<BudgetRepository>(
      () => BudgetRepositoryImpl(
        localDataSource: sl(),
        expenseRepository: sl<ExpenseRepository>(),
      ),
    );

    // Use Cases
    sl.registerLazySingleton(() => AddBudgetUseCase(sl(), sl<Uuid>()));
    sl.registerLazySingleton(() => GetBudgetsUseCase(sl()));
    sl.registerLazySingleton(() => UpdateBudgetUseCase(sl()));
    sl.registerLazySingleton(() => DeleteBudgetUseCase(sl()));

    // Blocs
    if (!sl.isRegistered<BudgetListBloc>()) {
      sl.registerFactory(
        () => BudgetListBloc(
          getBudgetsUseCase: sl(),
          deleteBudgetUseCase: sl(),
          expenseRepository: sl<ExpenseRepository>(), // Injected dependency
          dataChangeStream: sl<Stream<DataChangedEvent>>(),
        ),
      );
    }
    if (!sl.isRegistered<AddEditBudgetBloc>()) {
      sl.registerFactoryParam<AddEditBudgetBloc, Budget?, void>(
        (initialBudget, _) => AddEditBudgetBloc(
          addBudgetUseCase: sl(),
          updateBudgetUseCase: sl(),
          categoryRepository: sl<CategoryRepository>(),
          initialBudget: initialBudget,
        ),
      );
    }
  }
}
