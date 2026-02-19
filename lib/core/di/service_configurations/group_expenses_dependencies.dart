import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_remote_data_source.dart';
import 'package:expense_tracker/features/group_expenses/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/group_expenses/data/repositories/group_expenses_repository_impl.dart';
import 'package:expense_tracker/features/group_expenses/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/group_expenses/presentation/bloc/group_expenses_bloc.dart';
import 'package:hive_ce/hive.dart';

class GroupExpensesDependencies {
  static void register() {
    sl.registerLazySingleton<GroupExpensesLocalDataSource>(
      () => GroupExpensesLocalDataSourceImpl(sl<Box<GroupExpenseModel>>()),
    );
    sl.registerLazySingleton<GroupExpensesRemoteDataSource>(
      () => GroupExpensesRemoteDataSourceImpl(sl()),
    );

    sl.registerLazySingleton<GroupExpensesRepository>(
      () => GroupExpensesRepositoryImpl(
        localDataSource: sl(),
        remoteDataSource: sl(),
        outboxRepository: sl(),
        syncService: sl(),
        connectivity: sl(),
      ),
    );

    sl.registerFactoryParam<GroupExpensesBloc, String, void>(
      (groupId, _) => GroupExpensesBloc(sl())..add(LoadGroupExpenses(groupId)),
    );
  }
}
