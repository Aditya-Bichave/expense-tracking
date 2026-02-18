import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_expenses_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_members_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_members_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_expense_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/repositories/group_expenses_repository_impl.dart';
import 'package:expense_tracker/features/groups/data/repositories/groups_repository_impl.dart';
import 'package:expense_tracker/features/groups/domain/repositories/group_expenses_repository.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/domain/usecases/add_group_expense_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/get_group_expenses_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/get_groups_usecase.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups_usecase.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';
import 'package:expense_tracker/features/groups/domain/usecases/get_group_usecase.dart';

class GroupsDependencies {
  static Future<void> register() async {
    // Boxes
    if (!Hive.isBoxOpen('groups')) {
      await Hive.openBox<GroupModel>('groups');
    }
    if (!Hive.isBoxOpen('group_members')) {
      await Hive.openBox<GroupMemberModel>('group_members');
    }
    if (!Hive.isBoxOpen('group_expenses')) {
      await Hive.openBox<GroupExpenseModel>('group_expenses');
    }

    // DataSources
    sl.registerLazySingleton<GroupsLocalDataSource>(
      () => GroupsLocalDataSourceImpl(Hive.box<GroupModel>('groups')),
    );
    sl.registerLazySingleton<GroupsRemoteDataSource>(
      () => GroupsRemoteDataSourceImpl(),
    );
    sl.registerLazySingleton<GroupMembersLocalDataSource>(
      () => GroupMembersLocalDataSourceImpl(Hive.box<GroupMemberModel>('group_members')),
    );
    sl.registerLazySingleton<GroupMembersRemoteDataSource>(
      () => GroupMembersRemoteDataSourceImpl(),
    );
    sl.registerLazySingleton<GroupExpensesLocalDataSource>(
      () => GroupExpensesLocalDataSourceImpl(Hive.box<GroupExpenseModel>('group_expenses')),
    );
    sl.registerLazySingleton<GroupExpensesRemoteDataSource>(
      () => GroupExpensesRemoteDataSourceImpl(),
    );

    // Repositories
    sl.registerLazySingleton<GroupsRepository>(
      () => GroupsRepositoryImpl(
        localDataSource: sl(),
        remoteDataSource: sl(),
        membersLocalDataSource: sl(),
        membersRemoteDataSource: sl(),
        outboxRepository: sl(),
        authService: sl(),
        uuid: sl(),
      ),
    );
    sl.registerLazySingleton<GroupExpensesRepository>(
      () => GroupExpensesRepositoryImpl(
        localDataSource: sl(),
        remoteDataSource: sl(),
        outboxRepository: sl(),
        uuid: sl(),
      ),
    );

    // UseCases
    sl.registerLazySingleton(() => GetGroupsUseCase(sl()));
    sl.registerLazySingleton(() => CreateGroupUseCase(sl()));
    sl.registerLazySingleton(() => SyncGroupsUseCase(sl()));
    sl.registerLazySingleton(() => GetGroupExpensesUseCase(sl()));
    sl.registerLazySingleton(() => AddGroupExpenseUseCase(sl()));
    sl.registerLazySingleton(() => GetGroupUseCase(sl()));
  }
}
