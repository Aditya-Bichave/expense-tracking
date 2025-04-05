// lib/core/di/service_configuration/settings_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';

class SettingsDependencies {
  static void register() {
    // Data Source
    sl.registerLazySingleton<SettingsLocalDataSource>(
        () => SettingsLocalDataSourceImpl(prefs: sl()));
    // Repository
    sl.registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(localDataSource: sl()));
    // BLoC
    sl.registerFactory(() => SettingsBloc(settingsRepository: sl()));
  }
}
