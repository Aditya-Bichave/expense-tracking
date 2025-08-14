// lib/core/di/service_configurations/transactions_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';

class TransactionsDependencies {
  static void register() {
    // Use Cases (List/Hydration)
    sl.registerLazySingleton(() => GetTransactionsUseCase(
          expenseRepository: sl(),
          incomeRepository: sl(),
          categoryRepository: sl(),
        ));

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
          categorizeTransactionUseCase:
              sl(), // Assumes CategoriesDependencies registered
          expenseRepository: sl(),
          incomeRepository: sl(),
          categoryRepository: sl(), // Assumes CategoriesDependencies registered
        ));
  }
}
