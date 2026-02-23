import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockOutboxRepository extends Mock implements OutboxRepository {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}
class MockConnectivity extends Mock implements Connectivity {}
class MockGroupBox extends Mock implements Box<GroupModel> {}
class MockGroupMemberBox extends Mock implements Box<GroupMemberModel> {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder {
  final Object? error;
  FakePostgrestFilterBuilder({this.error});

  @override
  PostgrestFilterBuilder eq(String column, Object value) => this;

  @override
  Future<S> then<S>(FutureOr<S> Function(dynamic) onValue, {Function? onError}) {
    if (error != null) {
      return Future.error(error!, StackTrace.current).then((_) => onValue(null), onError: onError);
    }
    return Future.value([]).then((val) => onValue(val));
  }
}

void main() {
  late SyncService syncService;
  late MockOutboxRepository mockOutboxRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late MockConnectivity mockConnectivity;
  late MockGroupBox mockGroupBox;
  late MockGroupMemberBox mockGroupMemberBox;
  late StreamController<List<ConnectivityResult>> connectivityController;
  late MockRealtimeChannel mockChannel;

  setUpAll(() {
    registerFallbackValue(
      SyncMutationModel(
        id: 'fallback',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      ),
    );
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(MockRealtimeChannel());
  });

  setUp(() {
    mockOutboxRepository = MockOutboxRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockConnectivity = MockConnectivity();
    mockGroupBox = MockGroupBox();
    mockGroupMemberBox = MockGroupMemberBox();
    mockChannel = MockRealtimeChannel();
    connectivityController = StreamController<List<ConnectivityResult>>.broadcast();

    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => connectivityController.stream);

    when(() => mockSupabaseClient.channel(any())).thenReturn(mockChannel);
    when(() => mockChannel.onPostgresChanges(
      event: any(named: 'event'),
      schema: any(named: 'schema'),
      table: any(named: 'table'),
      callback: any(named: 'callback'),
    )).thenReturn(mockChannel);

    when(() => mockChannel.subscribe()).thenReturn(mockChannel);
    when(() => mockSupabaseClient.removeChannel(any())).thenAnswer((_) async => 'ok');

    syncService = SyncService(
      mockSupabaseClient,
      mockOutboxRepository,
      mockConnectivity,
      mockGroupBox,
      mockGroupMemberBox,
    );

    when(() => mockOutboxRepository.markAsFailed(any(), any()))
        .thenAnswer((_) async {});
  });

  tearDown(() {
    connectivityController.close();
    try {
        syncService.dispose();
    } catch (_) {}
  });

  group('processOutbox', () {
    test('should report error status if an item fails', () async {
      final item = SyncMutationModel(
        id: 'fail',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.upsert(any())).thenAnswer((_) => FakePostgrestFilterBuilder(error: 'Fail'));

      final states = <SyncServiceStatus>[];
      final sub = syncService.statusStream.listen(states.add);

      await syncService.processOutbox();
      await Future.delayed(Duration.zero);

      expect(states, contains(SyncServiceStatus.syncing));
      expect(states.last, SyncServiceStatus.error);

      sub.cancel();
    });
  });

  group('Realtime Handling', () {
    test('dispose should unsubscribe channels', () async {
      await syncService.initializeRealtime();
      syncService.dispose();
      verify(() => mockSupabaseClient.removeChannel(any())).called(2);
    });
  });
}
