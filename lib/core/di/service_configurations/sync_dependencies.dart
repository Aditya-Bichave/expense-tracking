import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/network/supabase_client_provider.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/core/sync/services/realtime_service.dart';
import 'package:expense_tracker/core/sync/services/sync_coordinator.dart';
import 'package:expense_tracker/core/sync/services/sync_service.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive.dart';

class SyncDependencies {
  static void register() {
    // AuthSessionService
    if (!sl.isRegistered<AuthSessionService>()) {
      sl.registerLazySingleton<AuthSessionService>(() => AuthSessionService());
    }

    // OutboxRepository
    if (!sl.isRegistered<OutboxRepository>()) {
      sl.registerLazySingleton<OutboxRepository>(
        () => OutboxRepository(sl<Box<OutboxItem>>()),
      );
    }

    // SyncService
    if (!sl.isRegistered<SyncService>()) {
      sl.registerLazySingleton<SyncService>(
        () =>
            SyncService(sl<OutboxRepository>(), SupabaseClientProvider.client),
      );
    }

    // RealtimeService
    if (!sl.isRegistered<RealtimeService>()) {
      sl.registerLazySingleton<RealtimeService>(() => RealtimeService());
    }

    // SyncCoordinator
    if (!sl.isRegistered<SyncCoordinator>()) {
      sl.registerLazySingleton<SyncCoordinator>(
        () => SyncCoordinator(
          sl<AuthSessionService>(),
          sl<SyncService>(),
          sl<RealtimeService>(),
        ),
      );
    }
  }
}
