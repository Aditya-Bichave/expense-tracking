// lib/core/di/service_configuration/transactions_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/get_transactions_usecase.dart';
import 'package:expense_tracker/features/transactions/domain/usecases/update_transaction_categorization.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/add_edit_transaction/add_edit_transaction_bloc.dart';
import 'package:expense_tracker/features/transactions/presentation/bloc/transaction_list_bloc.dart';

class TransactionsDependencies {
  static void register() {
    // Use Cases
    sl.registerLazySingleton(() => GetTransactionsUseCase(
          expenseRepository: sl(),
          incomeRepository: sl(),
          categoryRepository: sl(),
        ));
    sl.registerLazySingleton(() => UpdateTransactionCategorizationUseCase(
          expenseRepository: sl(),
          incomeRepository: sl(),
        ));

    // Blocs
    sl.registerFactory(() => TransactionListBloc(
          getTransactionsUseCase: sl(),
          deleteExpenseUseCase: sl(),
          deleteIncomeUseCase: sl(),
          applyCategoryToBatchUseCase: sl(),
          saveUserHistoryUseCase: sl(),
          updateTransactionCategorizationUseCase: sl(),
          dataChangeStream: sl<Stream<DataChangedEvent>>(),
        ));

    // Add/Edit Bloc (Depends on multiple features)
    sl.registerFactory<AddEditTransactionBloc>(() => AddEditTransactionBloc(
          addExpenseUseCase: sl(),
          updateExpenseUseCase: sl(),
          addIncomeUseCase: sl(),
          updateIncomeUseCase: sl(),
          categorizeTransactionUseCase: sl(),
          expenseRepository: sl(),
          incomeRepository: sl(),
          categoryRepository: sl(),
        ));
  }
}
