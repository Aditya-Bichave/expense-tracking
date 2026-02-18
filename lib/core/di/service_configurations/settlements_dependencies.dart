import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/features/settlements/data/datasources/settlements_local_data_source.dart';
import 'package:expense_tracker/features/settlements/data/datasources/settlements_remote_data_source.dart';
import 'package:expense_tracker/features/settlements/data/models/settlement_model.dart';
import 'package:expense_tracker/features/settlements/data/repositories/settlements_repository_impl.dart';
import 'package:expense_tracker/features/settlements/domain/repositories/settlements_repository.dart';
import 'package:expense_tracker/features/settlements/domain/usecases/add_settlement_usecase.dart';
import 'package:expense_tracker/features/settlements/domain/usecases/get_settlements_usecase.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

class SettlementsDependencies {
  static Future<void> register() async {
    if (!Hive.isBoxOpen('settlements')) {
      await Hive.openBox<SettlementModel>('settlements');
    }

    sl.registerLazySingleton<SettlementsLocalDataSource>(
      () => SettlementsLocalDataSourceImpl(
        Hive.box<SettlementModel>('settlements'),
      ),
    );
    sl.registerLazySingleton<SettlementsRemoteDataSource>(
      () => SettlementsRemoteDataSourceImpl(),
    );

    sl.registerLazySingleton<SettlementsRepository>(
      () => SettlementsRepositoryImpl(
        localDataSource: sl(),
        remoteDataSource: sl(),
        outboxRepository: sl(),
        uuid: sl(),
      ),
    );

    sl.registerLazySingleton(() => GetSettlementsUseCase(sl()));
    sl.registerLazySingleton(() => AddSettlementUseCase(sl()));
  }
}
