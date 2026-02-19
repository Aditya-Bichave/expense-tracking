import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:expense_tracker/core/sync/sync_coordinator.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:hive_ce/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncDependencies {
  static void register() {
    sl.registerLazySingleton<Connectivity>(() => Connectivity());

    sl.registerLazySingleton<OutboxRepository>(
      () => OutboxRepository(sl<Box<OutboxItem>>()),
    );

    sl.registerLazySingleton<SyncService>(() => SyncService(sl(), sl()));

    sl.registerLazySingleton<RealtimeService>(() => RealtimeService(sl()));

    sl.registerLazySingleton<SyncCoordinator>(
      () => SyncCoordinator(sl(), sl(), sl(), sl()),
    );
  }
}
