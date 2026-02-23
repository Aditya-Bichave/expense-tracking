import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/core/sync/sync_coordinator.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/core/sync/realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSyncService extends Mock implements SyncService {}

class MockRealtimeService extends Mock implements RealtimeService {}

class MockConnectivity extends Mock implements Connectivity {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockSession extends Mock implements Session {}

void main() {
  late SyncCoordinator syncCoordinator;
  late MockSyncService mockSyncService;
  late MockRealtimeService mockRealtimeService;
  late MockConnectivity mockConnectivity;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockGoTrueClient;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late StreamController<AuthState> authStateController;

  setUp(() {
    mockSyncService = MockSyncService();
    mockRealtimeService = MockRealtimeService();
    mockConnectivity = MockConnectivity();
    mockSupabaseClient = MockSupabaseClient();
    mockGoTrueClient = MockGoTrueClient();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();
    authStateController = StreamController<AuthState>.broadcast();

    when(() => mockSupabaseClient.auth).thenReturn(mockGoTrueClient);
    when(
      () => mockGoTrueClient.onAuthStateChange,
    ).thenAnswer((_) => authStateController.stream);
    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);

    // Stub processOutbox to return a completed Future
    when(() => mockSyncService.processOutbox()).thenAnswer((_) async {});
    when(() => mockSyncService.initializeRealtime()).thenAnswer((_) async {});
    when(() => mockRealtimeService.unsubscribe()).thenAnswer((_) {});

    syncCoordinator = SyncCoordinator(
      mockSyncService,
      mockRealtimeService,
      mockConnectivity,
      mockSupabaseClient,
    );
  });

  tearDown(() {
    syncCoordinator.dispose();
    connectivityController.close();
    authStateController.close();
  });

  test('initialize listens to connectivity and auth changes', () {
    syncCoordinator.initialize();

    verify(() => mockConnectivity.onConnectivityChanged).called(1);
    verify(() => mockGoTrueClient.onAuthStateChange).called(1);
  });

  test('connectivity change to mobile triggers processOutbox', () async {
    syncCoordinator.initialize();

    connectivityController.add([ConnectivityResult.mobile]);

    await Future.delayed(Duration.zero); // Wait for async listener

    verify(() => mockSyncService.processOutbox()).called(1);
  });

  test('connectivity change to wifi triggers processOutbox', () async {
    syncCoordinator.initialize();

    connectivityController.add([ConnectivityResult.wifi]);

    await Future.delayed(Duration.zero);

    verify(() => mockSyncService.processOutbox()).called(1);
  });

  test('connectivity change to none does not trigger processOutbox', () async {
    syncCoordinator.initialize();

    connectivityController.add([ConnectivityResult.none]);

    await Future.delayed(Duration.zero);

    verifyNever(() => mockSyncService.processOutbox());
  });

  test('auth change with session triggers processOutbox', () async {
    syncCoordinator.initialize();

    final mockSession = MockSession();
    authStateController.add(AuthState(AuthChangeEvent.signedIn, mockSession));

    await Future.delayed(Duration.zero);

    verify(() => mockSyncService.processOutbox()).called(1);
  });

  test('auth change without session unsubscribes realtime', () async {
    syncCoordinator.initialize();

    authStateController.add(AuthState(AuthChangeEvent.signedOut, null));

    await Future.delayed(Duration.zero);

    verify(() => mockRealtimeService.unsubscribe()).called(1);
  });
}
