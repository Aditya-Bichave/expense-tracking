import 'package:expense_tracker/features/liabilities/data/datasources/liability_local_data_source.dart';
import 'package:expense_tracker/features/liabilities/data/repositories/liability_repository_impl.dart';
import 'package:expense_tracker/features/liabilities/domain/repositories/liability_repository.dart';
import 'package:expense_tracker/features/liabilities/domain/usecases/add_liability.dart';
import 'package:expense_tracker/features/liabilities/domain/usecases/delete_liability.dart';
import 'package:expense_tracker/features/liabilities/domain/usecases/get_liabilities.dart';
import 'package:expense_tracker/features/liabilities/domain/usecases/update_liability.dart';
import 'package:expense_tracker/features/liabilities/presentation/bloc/add_edit_liability/add_edit_liability_bloc.dart';
import 'package:expense_tracker/features/liabilities/presentation/bloc/liability_list/liability_list_bloc.dart';

import '../service_locator.dart';

class LiabilitiesDependencies {
  static void register() {
    // DATA SOURCES
    sl.registerLazySingleton<LiabilityLocalDataSource>(
      () => LiabilityLocalDataSourceImpl(sl()),
    );

    // REPOSITORIES
    sl.registerLazySingleton<LiabilityRepository>(
      () => LiabilityRepositoryImpl(
        localDataSource: sl(),
        transferRepository: sl(),
      ),
    );

    // USE CASES
    sl.registerLazySingleton(() => AddLiability(sl()));
    sl.registerLazySingleton(() => GetLiabilities(sl()));
    sl.registerLazySingleton(() => UpdateLiability(sl()));
    sl.registerLazySingleton(() => DeleteLiability(sl()));

    // BLOCS
    sl.registerFactory(() => LiabilityListBloc(getLiabilities: sl()));
    sl.registerFactory(
      () => AddEditLiabilityBloc(
        addLiability: sl(),
        updateLiability: sl(),
        deleteLiability: sl(),
      ),
    );
  }
}
