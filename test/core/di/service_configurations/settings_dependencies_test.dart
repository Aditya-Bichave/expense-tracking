import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:expense_tracker/core/di/service_configurations/settings_dependencies.dart';
import 'package:expense_tracker/features/settings/domain/repositories/settings_repository.dart';
import 'package:expense_tracker/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:expense_tracker/features/settings/presentation/bloc/settings_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  final sl = GetIt.instance;

  setUp(() {
    sl.reset();
    sl.registerSingleton<SharedPreferences>(MockSharedPreferences());
    sl.registerSingleton<FlutterSecureStorage>(MockFlutterSecureStorage());
  });

  test('SettingsDependencies registers all dependencies', () {
    SettingsDependencies.register();

    expect(sl.isRegistered<SettingsLocalDataSource>(), true);
    expect(sl.isRegistered<SettingsRepository>(), true);
    expect(sl.isRegistered<LocalAuthentication>(), true);
    expect(sl.isRegistered<SettingsBloc>(), true);
  });
}
