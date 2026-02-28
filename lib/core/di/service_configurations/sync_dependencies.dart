import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:expense_tracker/core/sync/sync_coordinator.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:hive_ce/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class SyncDependencies {
  static void register() {
    if (!sl.isRegistered<Connectivity>()) {
      sl.registerLazySingleton<Connectivity>(() => Connectivity());
    }

    if (!sl.isRegistered<OutboxRepository>()) {
      sl.registerLazySingleton<OutboxRepository>(
        () => OutboxRepository(sl<Box<SyncMutationModel>>()),
      );
    }

    if (!sl.isRegistered<SyncService>()) {
      sl.registerLazySingleton<SyncService>(
        () => SyncService(
          sl(),
          sl(),
          sl(),
          sl<Box<GroupModel>>(),
          sl<Box<GroupMemberModel>>(),
        ),
      );
    }

    if (!sl.isRegistered<RealtimeService>()) {
      sl.registerLazySingleton<RealtimeService>(() => RealtimeService(sl()));
    }

    if (!sl.isRegistered<SyncCoordinator>()) {
      sl.registerLazySingleton<SyncCoordinator>(
        () => SyncCoordinator(sl(), sl(), sl(), sl()),
      );
    }
  }
}
