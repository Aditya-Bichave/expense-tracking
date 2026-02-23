import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/repositories/groups_repository_impl.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group.dart';
import 'package:expense_tracker/features/groups/domain/usecases/join_group.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups.dart';
import 'package:expense_tracker/features/groups/domain/usecases/watch_groups.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/create_group/create_group_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:hive_ce/hive.dart';

class GroupsDependencies {
  static void register() {
    sl.registerLazySingleton<GroupsLocalDataSource>(
      () => GroupsLocalDataSourceImpl(
        sl<Box<GroupModel>>(),
        sl<Box<GroupMemberModel>>(),
      ),
    );
    sl.registerLazySingleton<GroupsRemoteDataSource>(
      () => GroupsRemoteDataSourceImpl(sl()),
    );

    sl.registerLazySingleton<GroupsRepository>(
      () => GroupsRepositoryImpl(
        localDataSource: sl(),
        remoteDataSource: sl(),
        outboxRepository: sl(),
        syncService: sl(),
        connectivity: sl(),
      ),
    );

    // Usecases
    sl.registerLazySingleton(() => WatchGroups(sl()));
    sl.registerLazySingleton(() => CreateGroup(sl()));
    sl.registerLazySingleton(() => SyncGroups(sl()));
    sl.registerLazySingleton(() => JoinGroup(sl()));

    // Blocs
    sl.registerFactory(
      () => GroupsBloc(watchGroups: sl(), syncGroups: sl(), joinGroup: sl()),
    );

    sl.registerFactory(() => CreateGroupBloc(createGroup: sl(), uuid: sl()));
  }
}
