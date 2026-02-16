// lib/core/di/service_configurations/recurring_transactions_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/recurring_transactions/data/datasources/recurring_transaction_local_data_source.dart';
import 'package:expense_tracker/features/recurring_transactions/data/repositories/recurring_transaction_repository_impl.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/services/transaction_generation_service.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/delete_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/generate_transactions_on_launch.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_audit_logs_for_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rule_by_id.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rules.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/pause_resume_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/update_recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/add_edit_recurring_rule/add_edit_recurring_rule_bloc.dart';
import 'package:expense_tracker/features/recurring_transactions/presentation/bloc/recurring_list/recurring_list_bloc.dart';
import 'package:uuid/uuid.dart';

class RecurringTransactionsDependencies {
  static void register() {
    // Data sources
    sl.registerLazySingleton<RecurringTransactionLocalDataSource>(
      () => RecurringTransactionLocalDataSourceImpl(
        recurringRuleBox: sl(),
        recurringRuleAuditLogBox: sl(),
      ),
    );

    // Repositories
    sl.registerLazySingleton<RecurringTransactionRepository>(
      () => RecurringTransactionRepositoryImpl(localDataSource: sl()),
    );

    // Use cases
    sl.registerLazySingleton(() => AddRecurringRule(sl()));
    sl.registerLazySingleton(() => GetRecurringRules(sl()));
    sl.registerLazySingleton(() => GetRecurringRuleById(sl()));
    sl.registerLazySingleton(
      () => UpdateRecurringRule(
        repository: sl(),
        getRecurringRuleById: sl(),
        addAuditLog: sl(),
        uuid: sl<Uuid>(),
        userId: 'demo-user-id', // Replace with authenticated user ID
      ),
    );
    sl.registerLazySingleton(() => DeleteRecurringRule(sl()));
    sl.registerLazySingleton(() => AddAuditLog(sl()));
    sl.registerLazySingleton(() => GetAuditLogsForRule(sl()));
    sl.registerLazySingleton(
      () =>
          PauseResumeRecurringRule(repository: sl(), updateRecurringRule: sl()),
    );
    sl.registerLazySingleton(
      () => GenerateTransactionsOnLaunch(
        recurringTransactionRepository: sl(),
        categoryRepository: sl(),
        addExpense: sl(),
        addIncome: sl(),
        uuid: sl<Uuid>(),
      ),
    );

    // Services
    sl.registerLazySingleton(() => TransactionGenerationService(sl()));

    // BLoCs
    sl.registerFactory(
      () => RecurringListBloc(
        getRecurringRules: sl(),
        pauseResumeRecurringRule: sl(),
        deleteRecurringRule: sl(),
        dataChangedEventStream: sl(),
      ),
    );
    sl.registerFactory(
      () => AddEditRecurringRuleBloc(
        addRecurringRule: sl(),
        updateRecurringRule: sl(),
        uuid: sl<Uuid>(),
      ),
    );
  }
}
