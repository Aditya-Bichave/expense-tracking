// lib/core/di/service_configurations/transactions_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';
import 'package:expense_tracker/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/add_transfer.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/update_transfer.dart';
import 'package:expense_tracker/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:expense_tracker/features/transactions/data/datasources/transaction_local_data_source_proxy.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart';

class TransactionsDependencies {
  static void register() {
    // Data Sources
    sl.registerLazySingleton<TransactionLocalDataSource>(
        () => DemoAwareTransactionDataSource(
              hiveDataSource: sl<HiveTransactionLocalDataSource>(),
              demoModeService: sl<DemoModeService>(),
            ));

    // Repositories
    sl.registerLazySingleton<TransactionRepository>(() => TransactionRepositoryImpl(localDataSource: sl()));
    // Use Cases (List/Hydration)
    sl.registerLazySingleton(() => GetTransactionsUseCase(
          expenseRepository: sl(),
          incomeRepository: sl(),
          categoryRepository: sl(),
        ));
    sl.registerLazySingleton(() => AddTransferUseCase(sl()));
    sl.registerLazySingleton(() => UpdateTransferUseCase(sl()));

    // Blocs
    sl.registerFactory(() => TransactionListBloc(
          getTransactionsUseCase: sl(),
          deleteExpenseUseCase: sl(), // Assumes ExpensesDependencies registered
          deleteIncomeUseCase: sl(), // Assumes IncomeDependencies registered
          applyCategoryToBatchUseCase:
              sl(), // Assumes CategoriesDependencies registered
          saveUserHistoryUseCase:
              sl(), // Assumes CategoriesDependencies registered
          expenseRepository: sl(),
          incomeRepository: sl(),
          dataChangeStream: sl<Stream<DataChangedEvent>>(),
        ));

    // Add/Edit Bloc (Depends on multiple features)
    sl.registerFactory<AddEditTransactionBloc>(() => AddEditTransactionBloc(
          addExpenseUseCase: sl(),
          updateExpenseUseCase: sl(),
          addIncomeUseCase: sl(),
          updateIncomeUseCase: sl(),
          addTransferUseCase: sl(),
          updateTransferUseCase: sl(),
          categorizeTransactionUseCase:
              sl(), // Assumes CategoriesDependencies registered
          expenseRepository: sl(),
          incomeRepository: sl(),
          transactionRepository: sl(),
          categoryRepository: sl(), // Assumes CategoriesDependencies registered
        ));
  }
}
