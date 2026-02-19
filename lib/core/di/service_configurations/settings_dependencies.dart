// lib/core/di/service_configurations/settings_dependencies.dart
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/services/demo_mode_service.dart'; // Import Demo Service
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/data/repositories/settings_repository_impl.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:expense_tracker/features/settings/domain/usecases/toggle_app_lock.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SettingsDependencies {
  static void register() {
    // External
    if (!sl.isRegistered<FlutterSecureStorage>()) {
      sl.registerLazySingleton(() => const FlutterSecureStorage());
    }

    // Data Source
    sl.registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSourceImpl(prefs: sl(), secureStorage: sl()),
    );
    // Repository
    sl.registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(localDataSource: sl()),
    );
    // Use Case and external deps
    sl.registerLazySingleton<LocalAuthentication>(() => LocalAuthentication());
    sl.registerLazySingleton<ToggleAppLockUseCase>(
      () => ToggleAppLockUseCase(sl(), sl()),
    );
    // BLoC
    // Provide a single instance so router and app share the same stream
    sl.registerLazySingleton<SettingsBloc>(
      () => SettingsBloc(
        settingsRepository: sl<SettingsRepository>(),
        demoModeService: sl<DemoModeService>(), // Provide the dependency
        toggleAppLockUseCase: sl<ToggleAppLockUseCase>(),
      ),
    );
  }
}
