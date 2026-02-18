import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/invites/data/datasources/invites_remote_data_source.dart';
import 'package:expense_tracker/features/invites/data/models/invite_model.dart';
import 'package:expense_tracker/features/invites/data/repositories/invites_repository_impl.dart';
import 'package:expense_tracker/features/invites/domain/repositories/invites_repository.dart';
import 'package:expense_tracker/features/invites/domain/usecases/accept_invite_usecase.dart';
import 'package:expense_tracker/features/invites/domain/usecases/create_invite_usecase.dart';
import 'package:hive_ce/hive.dart';

class InvitesDependencies {
  static Future<void> register() async {
    // Box for invites (optional, if we cache)
    // await Hive.openBox<InviteModel>('invites');

    sl.registerLazySingleton<InvitesRemoteDataSource>(
      () => InvitesRemoteDataSourceImpl(),
    );

    sl.registerLazySingleton<InvitesRepository>(
      () => InvitesRepositoryImpl(sl()),
    );

    sl.registerLazySingleton(() => CreateInviteUseCase(sl()));
    sl.registerLazySingleton(() => AcceptInviteUseCase(sl()));
  }
}
