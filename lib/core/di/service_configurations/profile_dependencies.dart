import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:expense_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:expense_tracker/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/clear_profile_cache_usecase.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_bloc.dart';

class ProfileDependencies {
  static void register() {
    sl.registerLazySingleton<ProfileLocalDataSource>(
      () => ProfileLocalDataSourceImpl(sl()),
    );

    sl.registerLazySingleton<ProfileRemoteDataSource>(
      () => ProfileRemoteDataSourceImpl(sl()),
    );

    sl.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(sl(), sl(), sl()),
    );

    sl.registerLazySingleton(() => GetProfileUseCase(sl()));
    sl.registerLazySingleton(() => UpdateProfileUseCase(sl()));
    sl.registerLazySingleton(() => UploadAvatarUseCase(sl()));
    sl.registerLazySingleton(() => ClearProfileCacheUseCase(sl()));

    sl.registerFactory(() => ProfileBloc(sl(), sl(), sl()));
  }
}
