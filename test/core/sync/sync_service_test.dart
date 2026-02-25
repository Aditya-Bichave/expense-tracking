import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class MockGroupBox extends Mock implements Box<GroupModel> {}

class MockGroupMemberBox extends Mock implements Box<GroupMemberModel> {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

// Typed mocks for Supabase chain
class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

// Fake that can be awaited to return Map<String, dynamic>
class FakePostgrestTransformBuilder extends Fake
    implements PostgrestTransformBuilder<Map<String, dynamic>> {
  final Map<String, dynamic> result;

  FakePostgrestTransformBuilder(this.result);

  @override
  Future<S> then<S>(
    FutureOr<S> Function(Map<String, dynamic>) onValue, {
    Function? onError,
  }) {
    return Future.value(result).then(onValue, onError: onError);
  }
}

class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder<dynamic> {
  @override
  Future<S> then<S>(
    FutureOr<S> Function(dynamic) onValue, {
    Function? onError,
  }) {
    return Future.value([]).then(onValue, onError: onError);
  }

  @override
  PostgrestFilterBuilder<dynamic> eq(String column, Object value) {
    return this;
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
  late MockPostgrestFilterBuilder mockFilterBuilder;

  void Function(PostgresChangePayload)? groupCallback;
  void Function(PostgresChangePayload)? memberCallback;

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
    registerFallbackValue(
      GroupModel(
        id: 'f',
        name: 'f',
        createdBy: 'f',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        typeValue: 'f',
        currency: 'f',
      ),
    );
    registerFallbackValue(
      GroupMemberModel(
        id: 'f',
        groupId: 'f',
        userId: 'f',
        roleValue: 'f',
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(MockRealtimeChannel());

    // Register fallbacks for Supabase types if needed
    registerFallbackValue(MockPostgrestFilterBuilder());
  });

  setUp(() {
    mockOutboxRepository = MockOutboxRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    mockFilterBuilder = MockPostgrestFilterBuilder();
    mockConnectivity = MockConnectivity();
    mockGroupBox = MockGroupBox();
    mockGroupMemberBox = MockGroupMemberBox();
    mockChannel = MockRealtimeChannel();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(
      () => mockConnectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);

    when(
      () => mockSupabaseClient.channel(any()),
    ).thenAnswer((_) => mockChannel);

    when(
      () => mockChannel.onPostgresChanges(
        event: any(named: 'event'),
        schema: any(named: 'schema'),
        table: any(named: 'table'),
        callback: any(named: 'callback'),
      ),
    ).thenAnswer((invocation) {
      final table = invocation.namedArguments[#table] as String;
      final callback =
          invocation.namedArguments[#callback]
              as void Function(PostgresChangePayload);
      if (table == 'groups') groupCallback = callback;
      if (table == 'group_members') memberCallback = callback;
      return mockChannel;
    });

    when(() => mockChannel.subscribe()).thenAnswer((_) => mockChannel);
    when(
      () => mockSupabaseClient.removeChannel(any()),
    ).thenAnswer((_) async => 'ok');

    when(
      () => mockOutboxRepository.markAsFailed(any(), any()),
    ).thenAnswer((_) async {});
    when(() => mockOutboxRepository.markAsSent(any())).thenAnswer((_) async {});

    // Default mock behavior for containsKey
    when(() => mockGroupBox.containsKey(any())).thenReturn(true);

    syncService = SyncService(
      mockSupabaseClient,
      mockOutboxRepository,
      mockConnectivity,
      mockGroupBox,
      mockGroupMemberBox,
    );
  });

  tearDown(() {
    connectivityController.close();
    try {
      syncService.dispose();
    } catch (_) {}
  });

  group('Connectivity', () {
    test('should emit offline when connectivity is none', () async {
      final states = <SyncServiceStatus>[];
      final sub = syncService.statusStream.listen(states.add);

      // Emits synced in constructor immediately
      connectivityController.add([ConnectivityResult.none]);
      await Future.delayed(Duration.zero);

      expect(states, contains(SyncServiceStatus.offline));
      sub.cancel();
    });

    test('should call processOutbox when online', () async {
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([]);

      // Trigger online
      connectivityController.add([ConnectivityResult.wifi]);
      // The listen in SyncService constructor will call processOutbox()
      // We need to wait for it.
      await Future.delayed(const Duration(milliseconds: 10));

      verify(() => mockOutboxRepository.getPendingItems()).called(1);
    });
  });

  group('processOutbox', () {
    test('should successfully process different sync operations', () async {
      final createItem = SyncMutationModel(
        id: '1',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
      );
      final updateItem = SyncMutationModel(
        id: '2',
        table: 'groups',
        operation: OpType.update,
        payload: {},
        createdAt: DateTime.now(),
      );
      final deleteItem = SyncMutationModel(
        id: '3',
        table: 'groups',
        operation: OpType.delete,
        payload: {},
        createdAt: DateTime.now(),
      );

      var callCount = 0;
      when(() => mockOutboxRepository.getPendingItems()).thenAnswer((_) {
        if (callCount == 0) {
          callCount++;
          return [createItem, updateItem, deleteItem];
        }
        return [];
      });

      // Use thenAnswer for all builders
      when(
        () => mockSupabaseClient.from(any()),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.upsert(any()),
      ).thenAnswer((_) => FakePostgrestFilterBuilder());
      when(
        () => mockQueryBuilder.update(any()),
      ).thenAnswer((_) => FakePostgrestFilterBuilder());
      when(
        () => mockQueryBuilder.delete(),
      ).thenAnswer((_) => FakePostgrestFilterBuilder());

      final states = <SyncServiceStatus>[];
      final sub = syncService.statusStream.listen(states.add);

      await syncService.processOutbox();
      // Use short delay to allow all microtasks in processOutbox to finish
      await Future.delayed(const Duration(milliseconds: 50));

      verify(() => mockQueryBuilder.upsert(any())).called(1);
      verify(() => mockQueryBuilder.update(any())).called(1);
      verify(() => mockQueryBuilder.delete()).called(1);
      verify(() => mockOutboxRepository.markAsSent(any())).called(3);

      expect(states.last, SyncServiceStatus.synced);
      sub.cancel();
    });

    test('should skip max retries items', () async {
      final item = SyncMutationModel(
        id: 'max_retry',
        table: 'groups',
        operation: OpType.create,
        payload: {},
        createdAt: DateTime.now(),
        retryCount: 5,
      );
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);

      await syncService.processOutbox();

      verify(
        () => mockOutboxRepository.markAsFailed(item, 'Max retries exceeded.'),
      ).called(1);
      verifyNever(() => mockSupabaseClient.from(any()));
    });
  });

  group('Realtime Handling', () {
    test('groups realtime - insert and update', () async {
      await syncService.initializeRealtime();
      expect(groupCallback, isNotNull);

      final now = DateTime.now();
      when(() => mockGroupBox.get(any())).thenReturn(null);
      when(() => mockGroupBox.put(any(), any())).thenAnswer((_) async {});

      final payload = PostgresChangePayload(
        commitTimestamp: now,
        eventType: PostgresChangeEvent.insert,
        newRecord: {
          'id': 'g1',
          'name': 'G1',
          'type': 'trip',
          'currency': 'USD',
          'created_by': 'u1',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        oldRecord: {},
        table: 'groups',
        schema: 'public',
        errors: [],
      );

      groupCallback!(payload);
      verify(() => mockGroupBox.put('g1', any())).called(1);
    });

    test('groups realtime - delete', () async {
      await syncService.initializeRealtime();
      when(() => mockGroupBox.delete(any())).thenAnswer((_) async {});

      final payload = PostgresChangePayload(
        commitTimestamp: DateTime.now(),
        eventType: PostgresChangeEvent.delete,
        newRecord: {},
        oldRecord: {'id': 'g1'},
        table: 'groups',
        schema: 'public',
        errors: [],
      );

      groupCallback!(payload);
      verify(() => mockGroupBox.delete('g1')).called(1);
    });

    test('group_members realtime - insert and update', () async {
      await syncService.initializeRealtime();
      expect(memberCallback, isNotNull);

      final now = DateTime.now();
      when(() => mockGroupMemberBox.get(any())).thenReturn(null);
      when(() => mockGroupMemberBox.put(any(), any())).thenAnswer((_) async {});
      when(() => mockGroupBox.containsKey('g1')).thenReturn(true);

      final payload = PostgresChangePayload(
        commitTimestamp: now,
        eventType: PostgresChangeEvent.insert,
        newRecord: {
          'id': 'm1',
          'group_id': 'g1',
          'user_id': 'u1',
          'role': 'admin',
          'joined_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        oldRecord: {},
        table: 'group_members',
        schema: 'public',
        errors: [],
      );

      memberCallback!(payload);
      verify(() => mockGroupMemberBox.put('m1', any())).called(1);
      // containsKey called to check if group needs fetching
      verify(() => mockGroupBox.containsKey('g1')).called(1);
    });

    test('group_members realtime - inserts missing group', () async {
      await syncService.initializeRealtime();
      expect(memberCallback, isNotNull);

      final now = DateTime.now();
      when(() => mockGroupMemberBox.get(any())).thenReturn(null);
      when(() => mockGroupMemberBox.put(any(), any())).thenAnswer((_) async {});

      // Simulate group missing locally
      when(() => mockGroupBox.containsKey('g1')).thenReturn(false);

      // Mock fetching group from Supabase
      // Use thenAnswer for Future-implementing builders
      when(
        () => mockSupabaseClient.from('groups'),
      ).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.select(),
      ).thenAnswer((_) => mockFilterBuilder);
      when(
        () => mockFilterBuilder.eq('id', 'g1'),
      ).thenAnswer((_) => mockFilterBuilder);

      // Use thenAnswer with synchronous closure returning Future-like Fake
      when(() => mockFilterBuilder.single()).thenAnswer(
        (_) => FakePostgrestTransformBuilder({
          'id': 'g1',
          'name': 'G1',
          'type': 'trip',
          'currency': 'USD',
          'created_by': 'u1',
          'created_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        }),
      );

      when(() => mockGroupBox.put('g1', any())).thenAnswer((_) async {});

      final payload = PostgresChangePayload(
        commitTimestamp: now,
        eventType: PostgresChangeEvent.insert,
        newRecord: {
          'id': 'm1',
          'group_id': 'g1',
          'user_id': 'u1',
          'role': 'admin',
          'joined_at': now.toIso8601String(),
          'updated_at': now.toIso8601String(),
        },
        oldRecord: {},
        table: 'group_members',
        schema: 'public',
        errors: [],
      );

      memberCallback!(payload);

      // Wait for async fetch
      await Future.delayed(const Duration(milliseconds: 10));

      verify(() => mockGroupMemberBox.put('m1', any())).called(1);
      verify(() => mockGroupBox.containsKey('g1')).called(1);
      verify(() => mockSupabaseClient.from('groups')).called(1);
      verify(() => mockGroupBox.put('g1', any())).called(1);
    });

    test('group_members realtime - delete', () async {
      await syncService.initializeRealtime();
      when(() => mockGroupMemberBox.delete(any())).thenAnswer((_) async {});

      final payload = PostgresChangePayload(
        commitTimestamp: DateTime.now(),
        eventType: PostgresChangeEvent.delete,
        newRecord: {},
        oldRecord: {'id': 'm1'},
        table: 'group_members',
        schema: 'public',
        errors: [],
      );

      memberCallback!(payload);
      verify(() => mockGroupMemberBox.delete('m1')).called(1);
    });
  });
}
