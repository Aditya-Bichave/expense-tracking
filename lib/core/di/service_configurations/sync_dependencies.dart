import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_coordinator.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart'; // Correct import
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart'; // Correct import

class SyncDependencies {
  static void register() {
    sl.registerLazySingleton<Connectivity>(() => Connectivity());

    sl.registerLazySingleton<OutboxRepository>(() => OutboxRepository(sl()));

    sl.registerLazySingleton<SyncService>(() => SyncService(sl(), sl()));

    sl.registerLazySingleton<RealtimeService>(
      () => RealtimeService(
        sl(),
        sl<GroupsLocalDataSource>(), // Add missing arguments
        sl<GroupExpensesLocalDataSource>(), // Add missing arguments
      ),
    );
    sl.registerLazySingleton<SyncCoordinator>(
      () => SyncCoordinator(sl(), sl(), sl(), sl()),
    );
  }
}
