// lib/core/di/service_configurations/categories_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/category_predefined_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/merchant_category_data_source.dart';
import 'package:expense_tracker/features/categories/data/datasources/user_history_local_data_source.dart';
import 'package:expense_tracker/features/categories/data/repositories/category_repository_impl.dart';
import 'package:expense_tracker/features/categories/data/repositories/merchant_category_repository_impl.dart';
import 'package:expense_tracker/features/categories/data/repositories/user_history_repository_impl.dart';
import 'package:expense_tracker/features/categories/domain/repositories/category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/merchant_category_repository.dart';
import 'package:expense_tracker/features/categories/domain/repositories/user_history_repository.dart';
import 'package:expense_tracker/features/categories/domain/usecases/add_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/apply_category_to_batch.dart';
import 'package:expense_tracker/features/categories/domain/usecases/categorize_transaction.dart';
import 'package:expense_tracker/features/categories/domain/usecases/delete_custom_category.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_expense_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/get_income_categories.dart';
import 'package:expense_tracker/features/categories/domain/usecases/save_user_categorization_history.dart';
import 'package:expense_tracker/features/categories/domain/usecases/update_custom_category.dart';
import 'package:expense_tracker/features/categories/presentation/bloc/category_management/category_management_bloc.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart'; // Dependency
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart'; // Dependency

class CategoriesDependencies {
  static void register() {
    // Data Sources
    sl.registerLazySingleton<CategoryLocalDataSource>(
      () => HiveCategoryLocalDataSource(sl()),
    );
    sl.registerLazySingleton<CategoryPredefinedDataSource>(
      () => AssetExpenseCategoryDataSource(),
      instanceName: 'expensePredefined',
    );
    sl.registerLazySingleton<CategoryPredefinedDataSource>(
      () => AssetIncomeCategoryDataSource(),
      instanceName: 'incomePredefined',
    );
    sl.registerLazySingleton<UserHistoryLocalDataSource>(
      () => HiveUserHistoryLocalDataSource(sl()),
    );
    sl.registerLazySingleton<MerchantCategoryDataSource>(
      () => AssetMerchantCategoryDataSource(),
    );
    // Repositories (Depend on Income/Expense repos)
    sl.registerLazySingleton<CategoryRepository>(
      () => CategoryRepositoryImpl(
        localDataSource: sl<CategoryLocalDataSource>(),
        expensePredefinedDataSource: sl<CategoryPredefinedDataSource>(
          instanceName: 'expensePredefined',
        ),
        incomePredefinedDataSource: sl<CategoryPredefinedDataSource>(
          instanceName: 'incomePredefined',
        ),
      ),
    );
    sl.registerLazySingleton<UserHistoryRepository>(
      () => UserHistoryRepositoryImpl(localDataSource: sl()),
    );
    sl.registerLazySingleton<MerchantCategoryRepository>(
      () => MerchantCategoryRepositoryImpl(dataSource: sl()),
    );
    // Use Cases
    sl.registerLazySingleton(() => GetCategoriesUseCase(sl()));
    sl.registerLazySingleton(() => GetExpenseCategoriesUseCase(sl()));
    sl.registerLazySingleton(() => GetIncomeCategoriesUseCase(sl()));
    sl.registerLazySingleton(
      () => AddCustomCategoryUseCase(sl(), sl()),
    ); // Inject Uuid
    sl.registerLazySingleton(() => UpdateCustomCategoryUseCase(sl()));
    sl.registerLazySingleton(
      () => DeleteCustomCategoryUseCase(
        sl(),
        sl<ExpenseRepository>(),
        sl<IncomeRepository>(),
      ),
    ); // Inject Repos
    sl.registerLazySingleton(
      () => SaveUserCategorizationHistoryUseCase(sl(), sl()),
    ); // Inject Uuid
    sl.registerLazySingleton(
      () => CategorizeTransactionUseCase(
        userHistoryRepository: sl(),
        merchantCategoryRepository: sl(),
        categoryRepository: sl(),
      ),
    );
    sl.registerLazySingleton(
      () => ApplyCategoryToBatchUseCase(
        expenseRepository: sl<ExpenseRepository>(),
        incomeRepository: sl<IncomeRepository>(),
      ),
    ); // Inject Repos
    // Bloc
    sl.registerFactory(
      () => CategoryManagementBloc(
        getCategoriesUseCase: sl(),
        addCustomCategoryUseCase: sl(),
        updateCustomCategoryUseCase: sl(),
        deleteCustomCategoryUseCase: sl(),
      ),
    );
  }
}
