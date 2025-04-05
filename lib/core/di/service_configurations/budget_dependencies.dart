// lib/core/di/service_configurations/budget_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/budgets/data/datasources/budget_local_data_source.dart';
import 'package:expense_tracker/features/budgets/data/repositories/budget_repository_impl.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/add_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/get_budgets.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/update_budget.dart';
import 'package:expense_tracker/features/budgets/domain/usecases/delete_budget.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/add_edit_budget/add_edit_budget_bloc.dart';
import 'package:expense_tracker/features/budgets/presentation/bloc/budget_list/budget_list_bloc.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:uuid/uuid.dart';

class BudgetDependencies {
  static void register() {
    // Data Source
    sl.registerLazySingleton<BudgetLocalDataSource>(
        () => HiveBudgetLocalDataSource(sl()));

    // Repository (Depends on Expense Repo)
    sl.registerLazySingleton<BudgetRepository>(() => BudgetRepositoryImpl(
          localDataSource: sl(),
          expenseRepository: sl<ExpenseRepository>(),
        ));

    // Use Cases
    sl.registerLazySingleton(() => AddBudgetUseCase(sl(), sl<Uuid>()));
    sl.registerLazySingleton(() => GetBudgetsUseCase(sl()));
    sl.registerLazySingleton(() => UpdateBudgetUseCase(sl())); // ADDED
    sl.registerLazySingleton(() => DeleteBudgetUseCase(sl())); // ADDED

    // Defer Registering Update/Delete Use Cases until Phase 3

    // Blocs
    sl.registerFactory(() => BudgetListBloc(
          getBudgetsUseCase: sl(),
          budgetRepository: sl(), // Inject repo for calculations
          dataChangeStream: sl<Stream<DataChangedEvent>>(),
          deleteBudgetUseCase: sl(), dataChangedStream: sl(),
        ));
    sl.registerFactoryParam<AddEditBudgetBloc, Budget?, void>(
        (initialBudget, _) => AddEditBudgetBloc(
              addBudgetUseCase: sl(),
              categoryRepository:
                  sl<CategoryRepository>(), // Needed for form category list
              // updateBudgetUseCase: sl(), // Add later
              initialBudget: initialBudget,
              updateBudgetUseCase: sl(),
            ));
    sl.registerFactoryParam<AddEditBudgetBloc, Budget?, void>(
        (initialBudget, _) => AddEditBudgetBloc(
              addBudgetUseCase: sl(),
              updateBudgetUseCase: sl(), // Pass Update UseCase
              categoryRepository: sl<CategoryRepository>(),
              initialBudget: initialBudget,
            ));
  }
}
