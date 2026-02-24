import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_otp_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_magic_link_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/logout_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:app_links/app_links.dart';
import 'package:expense_tracker/features/deep_link/presentation/bloc/deep_link_bloc.dart';

class AuthDependencies {
  static void register() {
    sl.registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSourceImpl(sl()),
    );

    sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(sl()));

    sl.registerLazySingleton(() => LoginWithOtpUseCase(sl()));
    sl.registerLazySingleton(() => LoginWithMagicLinkUseCase(sl()));
    sl.registerLazySingleton(() => VerifyOtpUseCase(sl()));
    sl.registerLazySingleton(() => LogoutUseCase(sl()));
    sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

    sl.registerFactory(() => AuthBloc(sl(), sl(), sl(), sl(), sl()));

    sl.registerLazySingleton(() => SessionCubit(sl(), sl(), sl()));

    sl.registerLazySingleton<AppLinks>(() => AppLinks());
    sl.registerLazySingleton(
      () => DeepLinkBloc(sl<AppLinks>(), sl(), sl<AuthRepository>()),
    );
  }
}
