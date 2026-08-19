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

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockConnectivity extends Mock implements Connectivity {}

class MockBox<T> extends Mock implements Box<T> {}

class MockQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

class _FakeGroupModel extends Fake implements GroupModel {}

class _FakeGroupMemberModel extends Fake implements GroupMemberModel {}

class _FakeRealtimeChannel extends Fake implements RealtimeChannel {}

/// Postgrest's builders *are* Futures, so a plain mock cannot be awaited.
/// These fakes make the chain awaitable and record the `.eq()` filters, which
/// is the only way to assert that a delete targeted the right key.
class _FakeTransformBuilder<T> extends Mock
    implements PostgrestTransformBuilder<T> {
  _FakeTransformBuilder(this._value);

  final T _value;

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T value) onValue, {
    Function? onError,
  }) async => onValue(_value);
}

class _FakeFilterBuilder<T> extends Mock implements PostgrestFilterBuilder<T> {
  _FakeFilterBuilder(this._value, {PostgrestList selectResult = const []})
    : _selectResult = selectResult;

  final T _value;
  final PostgrestList _selectResult;
  final List<MapEntry<String, Object>> eqCalls = [];

  @override
  PostgrestFilterBuilder<T> eq(String column, Object value) {
    eqCalls.add(MapEntry(column, value));
    return this;
  }

  @override
  PostgrestTransformBuilder<PostgrestList> select([String columns = '*']) =>
      _FakeTransformBuilder<PostgrestList>(_selectResult);

  @override
  Future<U> then<U>(
    FutureOr<U> Function(T value) onValue, {
    Function? onError,
  }) async => onValue(_value);
}

/// SyncService is the offline write path: an outbox drained against Supabase,
/// plus realtime fan-in that has to resolve conflicts last-write-wins. Both
/// halves can silently corrupt user data — a stale realtime row overwriting a
/// newer local edit, or an outbox item retried forever — so the tests below
/// pin the ordering and the give-up conditions rather than just line-walking.
void main() {
  late MockSupabaseClient client;
  late MockOutboxRepository outbox;
  late MockConnectivity connectivity;
  late MockBox<GroupModel> groupBox;
  late MockBox<GroupMemberModel> groupMemberBox;
  late StreamController<List<ConnectivityResult>> connectivityController;

  SyncMutationModel mutation({
    String id = 'm1',
    String table = 'expenses',
    OpType operation = OpType.create,
    Map<String, dynamic>? payload,
    int retryCount = 0,
  }) => SyncMutationModel(
    id: id,
    table: table,
    operation: operation,
    payload: payload ?? {'amount': 10},
    createdAt: DateTime(2024, 1, 1),
    retryCount: retryCount,
  );

  Map<String, dynamic> groupJson({
    String id = 'g1',
    required String updatedAt,
    String name = 'Trip',
  }) => {
    'id': id,
    'name': name,
    'created_by': 'u1',
    'created_at': '2024-01-01T00:00:00.000Z',
    'updated_at': updatedAt,
    'type': 'custom',
    'currency': 'USD',
    'photo_url': null,
    'is_archived': false,
  };

  Map<String, dynamic> memberJson({
    String id = 'gm1',
    String groupId = 'g1',
    required String updatedAt,
  }) => {
    'id': id,
    'group_id': groupId,
    'user_id': 'u1',
    'role': 'member',
    'joined_at': '2024-01-01T00:00:00.000Z',
    'updated_at': updatedAt,
  };

  GroupModel storedGroup({String id = 'g1', required DateTime updatedAt}) =>
      GroupModel(
        id: id,
        name: 'Trip',
        createdBy: 'u1',
        createdAt: DateTime(2024, 1, 1),
        updatedAt: updatedAt,
        typeValue: 'custom',
        currency: 'USD',
        isArchived: false,
      );

  GroupMemberModel member({
    String id = 'gm1',
    String groupId = 'g1',
    required DateTime updatedAt,
  }) => GroupMemberModel(
    id: id,
    groupId: groupId,
    userId: 'u1',
    roleValue: 'member',
    joinedAt: DateTime(2024, 1, 1),
    updatedAt: updatedAt,
  );

  PostgresChangePayload payload({
    required PostgresChangeEvent event,
    Map<String, dynamic> newRecord = const {},
    Map<String, dynamic> oldRecord = const {},
    String table = 'groups',
  }) => PostgresChangePayload(
    schema: 'public',
    table: table,
    commitTimestamp: DateTime(2024, 6, 1),
    eventType: event,
    newRecord: newRecord,
    oldRecord: oldRecord,
    errors: null,
  );

  setUpAll(() {
    registerFallbackValue(_FakeGroupModel());
    registerFallbackValue(_FakeGroupMemberModel());
    registerFallbackValue(_FakeRealtimeChannel());
    registerFallbackValue(PostgresChangeEvent.all);
    registerFallbackValue(
      SyncMutationModel(
        id: 'fallback',
        table: 'fallback',
        operation: OpType.create,
        payload: const {},
        createdAt: DateTime(2024, 1, 1),
      ),
    );
  });

  setUp(() {
    client = MockSupabaseClient();
    outbox = MockOutboxRepository();
    connectivity = MockConnectivity();
    groupBox = MockBox<GroupModel>();
    groupMemberBox = MockBox<GroupMemberModel>();
    connectivityController =
        StreamController<List<ConnectivityResult>>.broadcast();

    when(
      () => connectivity.onConnectivityChanged,
    ).thenAnswer((_) => connectivityController.stream);
    when(() => outbox.getPendingItems()).thenReturn([]);
    when(() => outbox.markAsSent(any())).thenAnswer((_) async {});
    when(() => outbox.markAsFailed(any(), any())).thenAnswer((_) async {});
    when(() => groupBox.put(any(), any())).thenAnswer((_) async {});
    when(() => groupMemberBox.put(any(), any())).thenAnswer((_) async {});
    when(() => groupBox.delete(any())).thenAnswer((_) async {});
    when(() => groupMemberBox.delete(any())).thenAnswer((_) async {});
    when(() => groupBox.containsKey(any())).thenReturn(true);
  });

  tearDown(() async {
    await connectivityController.close();
  });

  SyncService build() =>
      SyncService(client, outbox, connectivity, groupBox, groupMemberBox);

  group('connectivity', () {
    test('losing the connection reports offline', () async {
      final service = build();
      final statuses = <SyncServiceStatus>[];
      service.statusStream.listen(statuses.add);

      connectivityController.add([ConnectivityResult.none]);
      await pumpEventQueue();

      expect(statuses, contains(SyncServiceStatus.offline));
      // Nothing should be drained while offline.
      verifyNever(() => outbox.getPendingItems());
      service.dispose();
    });

    test('regaining the connection drains the outbox', () async {
      final service = build();

      connectivityController.add([ConnectivityResult.wifi]);
      await pumpEventQueue();

      verify(() => outbox.getPendingItems()).called(greaterThanOrEqualTo(1));
      service.dispose();
    });

    test('a status emitted after dispose is dropped, not thrown', () async {
      final service = build();
      service.dispose();

      // The controller is closed by dispose; the guard has to swallow this.
      expect(
        () => connectivityController.add([ConnectivityResult.none]),
        returnsNormally,
      );
      await pumpEventQueue();
    });
  });

  group('processOutbox', () {
    test('an empty queue settles on synced', () async {
      final service = build();
      final statuses = <SyncServiceStatus>[];
      service.statusStream.listen(statuses.add);

      await service.processOutbox();
      await pumpEventQueue();

      expect(statuses, [SyncServiceStatus.syncing, SyncServiceStatus.synced]);
      service.dispose();
    });

    test('an item past the retry cap is failed, never sent', () async {
      final exhausted = mutation(retryCount: 5);
      when(() => outbox.getPendingItems()).thenReturn([exhausted]);
      final service = build();

      await service.processOutbox();

      verify(
        () => outbox.markAsFailed(exhausted, 'Max retries exceeded.'),
      ).called(1);
      verifyNever(() => outbox.markAsSent(any()));
      // It must not reach the network at all.
      verifyNever(() => client.from(any()));
      service.dispose();
    });

    test('a failing item is recorded and the run ends in error', () async {
      final item = mutation();
      when(() => outbox.getPendingItems()).thenReturn([item]);
      final queryBuilder = MockQueryBuilder();
      when(() => client.from(any())).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.upsert(any()),
      ).thenThrow(const PostgrestException(message: 'duplicate key'));

      final service = build();
      final statuses = <SyncServiceStatus>[];
      service.statusStream.listen(statuses.add);

      await service.processOutbox();
      await pumpEventQueue();

      verify(
        () => outbox.markAsFailed(item, any(that: contains('duplicate key'))),
      ).called(1);
      expect(statuses.last, SyncServiceStatus.error);
      service.dispose();
    });

    test('one bad item does not stop the next one', () async {
      final bad = mutation(id: 'bad');
      final good = mutation(id: 'good', table: 'incomes');
      when(() => outbox.getPendingItems()).thenReturn([bad, good]);

      final badBuilder = MockQueryBuilder();
      final goodBuilder = MockQueryBuilder();
      when(() => client.from('expenses')).thenAnswer((_) => badBuilder);
      when(() => client.from('incomes')).thenAnswer((_) => goodBuilder);
      when(
        () => badBuilder.upsert(any()),
      ).thenThrow(const PostgrestException(message: 'boom'));
      when(
        () => goodBuilder.upsert(any()),
      ).thenAnswer((_) => _FakeFilterBuilder<dynamic>(null));

      final service = build();
      await service.processOutbox();

      verify(() => outbox.markAsFailed(bad, any())).called(1);
      verify(() => outbox.markAsSent(good)).called(1);
      service.dispose();
    });

    test('a second call while one is in flight is dropped', () async {
      final completer = Completer<void>();
      when(() => outbox.getPendingItems()).thenAnswer((_) {
        // Block the first run inside the loop body.
        if (!completer.isCompleted) return [mutation()];
        return [];
      });
      final queryBuilder = MockQueryBuilder();
      when(() => client.from(any())).thenAnswer((_) => queryBuilder);
      when(
        () => queryBuilder.upsert(any()),
      ).thenAnswer((_) => _FakeFilterBuilder<dynamic>(null));

      final service = build();
      final first = service.processOutbox();
      // Re-entering before the first finishes must be a no-op.
      await service.processOutbox();
      completer.complete();
      await first;

      // Only the first run drained; the re-entrant call returned immediately.
      verify(() => outbox.markAsSent(any())).called(1);
      service.dispose();
    });
  });

  group('outbox operations', () {
    late MockQueryBuilder queryBuilder;

    setUp(() {
      queryBuilder = MockQueryBuilder();
      when(() => client.from(any())).thenAnswer((_) => queryBuilder);
    });

    test('an update that matches no rows falls back to upsert', () async {
      final item = mutation(
        id: 'u1',
        operation: OpType.update,
        payload: {'name': 'renamed'},
      );
      when(() => outbox.getPendingItems()).thenReturn([item]);
      // Empty select result == zero rows updated.
      when(
        () => queryBuilder.update(any()),
      ).thenAnswer((_) => _FakeFilterBuilder<dynamic>(null, selectResult: []));
      when(
        () => queryBuilder.upsert(any()),
      ).thenAnswer((_) => _FakeFilterBuilder<dynamic>(null));

      final service = build();
      await service.processOutbox();

      // The fallback is what stops an offline edit silently vanishing when the
      // row does not exist on the server yet.
      verify(() => queryBuilder.upsert(any())).called(1);
      verify(() => outbox.markAsSent(item)).called(1);
      service.dispose();
    });

    test('an update that matches a row does not upsert', () async {
      final item = mutation(
        id: 'u1',
        operation: OpType.update,
        payload: {'name': 'renamed'},
      );
      when(() => outbox.getPendingItems()).thenReturn([item]);
      when(() => queryBuilder.update(any())).thenAnswer(
        (_) => _FakeFilterBuilder<dynamic>(
          null,
          selectResult: [
            {'id': 'u1'},
          ],
        ),
      );

      final service = build();
      await service.processOutbox();

      verifyNever(() => queryBuilder.upsert(any()));
      service.dispose();
    });

    test('a group_members delete targets the composite key', () async {
      final item = mutation(
        id: 'gm-del',
        table: 'group_members',
        operation: OpType.delete,
        payload: {'group_id': 'g1', 'user_id': 'u9'},
      );
      when(() => outbox.getPendingItems()).thenReturn([item]);
      final deleteBuilder = _FakeFilterBuilder<dynamic>(null);
      when(() => queryBuilder.delete()).thenAnswer((_) => deleteBuilder);

      final service = build();
      await service.processOutbox();

      // Deleting by the outbox id here would remove the wrong membership row.
      expect(deleteBuilder.eqCalls.map((e) => e.key), ['group_id', 'user_id']);
      expect(deleteBuilder.eqCalls.map((e) => e.value), ['g1', 'u9']);
      service.dispose();
    });

    test('any other delete targets the row id', () async {
      final item = mutation(
        id: 'e9',
        table: 'expenses',
        operation: OpType.delete,
        payload: const {},
      );
      when(() => outbox.getPendingItems()).thenReturn([item]);
      final deleteBuilder = _FakeFilterBuilder<dynamic>(null);
      when(() => queryBuilder.delete()).thenAnswer((_) => deleteBuilder);

      final service = build();
      await service.processOutbox();

      expect(deleteBuilder.eqCalls.single.key, 'id');
      expect(deleteBuilder.eqCalls.single.value, 'e9');
      service.dispose();
    });

    test('an expense carrying splits writes the relation tables', () async {
      final item = mutation(
        id: 'x1',
        table: 'expenses',
        payload: {
          'amount': 30,
          'payers': [
            {'userId': 'u1', 'amount': 30},
          ],
          'splits': [
            {'userId': 'u2', 'amount': 15, 'splitTypeValue': 'equal'},
          ],
        },
      );
      when(() => outbox.getPendingItems()).thenReturn([item]);

      final expenseBuilder = MockQueryBuilder();
      final payerBuilder = MockQueryBuilder();
      final splitBuilder = MockQueryBuilder();
      when(() => client.from('expenses')).thenAnswer((_) => expenseBuilder);
      when(() => client.from('expense_payers')).thenAnswer((_) => payerBuilder);
      when(() => client.from('expense_splits')).thenAnswer((_) => splitBuilder);
      when(
        () => expenseBuilder.upsert(any()),
      ).thenAnswer((_) => _FakeFilterBuilder<dynamic>(null));
      for (final b in [payerBuilder, splitBuilder]) {
        when(() => b.delete()).thenAnswer((_) => _FakeFilterBuilder(null));
        when(() => b.insert(any())).thenAnswer((_) => _FakeFilterBuilder(null));
      }

      final service = build();
      await service.processOutbox();

      // The nested lists must not be posted to `expenses` itself.
      final upserted =
          verify(() => expenseBuilder.upsert(captureAny())).captured.single
              as Map<String, dynamic>;
      expect(upserted.containsKey('payers'), isFalse);
      expect(upserted.containsKey('splits'), isFalse);
      expect(upserted['id'], 'x1');

      final payers =
          verify(() => payerBuilder.insert(captureAny())).captured.single
              as List<dynamic>;
      expect(payers.single, {
        'expense_id': 'x1',
        'payer_user_id': 'u1',
        'amount': 30,
      });

      final splits =
          verify(() => splitBuilder.insert(captureAny())).captured.single
              as List<dynamic>;
      expect(splits.single, {
        'expense_id': 'x1',
        'user_id': 'u2',
        'amount': 15,
        'split_type': 'equal',
      });
      service.dispose();
    });
  });

  group('realtime group changes', () {
    late void Function(PostgresChangePayload) groupCallback;
    late void Function(PostgresChangePayload) memberCallback;
    late SyncService service;

    setUp(() async {
      final groupsChannel = MockRealtimeChannel();
      final membersChannel = MockRealtimeChannel();
      when(() => client.channel('public:groups')).thenReturn(groupsChannel);
      when(
        () => client.channel('public:group_members'),
      ).thenReturn(membersChannel);
      when(() => client.removeChannel(any())).thenAnswer((_) async => 'ok');

      for (final channel in [groupsChannel, membersChannel]) {
        when(() => channel.subscribe()).thenReturn(channel);
      }
      when(
        () => groupsChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        ),
      ).thenAnswer((invocation) {
        groupCallback =
            invocation.namedArguments[#callback]
                as void Function(PostgresChangePayload);
        return groupsChannel;
      });
      when(
        () => membersChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        ),
      ).thenAnswer((invocation) {
        memberCallback =
            invocation.namedArguments[#callback]
                as void Function(PostgresChangePayload);
        return membersChannel;
      });

      service = build();
      await service.initializeRealtime();
    });

    tearDown(() => service.dispose());

    test('an unknown group is stored', () {
      when(() => groupBox.get('g1')).thenReturn(null);

      groupCallback(
        payload(
          event: PostgresChangeEvent.insert,
          newRecord: groupJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ),
      );

      verify(() => groupBox.put('g1', any())).called(1);
    });

    test('a newer server group overwrites the local copy', () {
      when(
        () => groupBox.get('g1'),
      ).thenReturn(storedGroup(updatedAt: DateTime.utc(2024, 1, 1)));

      groupCallback(
        payload(
          event: PostgresChangeEvent.update,
          newRecord: groupJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ),
      );

      verify(() => groupBox.put('g1', any())).called(1);
    });

    test('a stale server group is ignored', () {
      when(
        () => groupBox.get('g1'),
      ).thenReturn(storedGroup(updatedAt: DateTime.utc(2024, 12, 1)));

      groupCallback(
        payload(
          event: PostgresChangeEvent.update,
          newRecord: groupJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ),
      );

      // Last-write-wins: an out-of-order realtime frame must not clobber a
      // newer local edit.
      verifyNever(() => groupBox.put(any(), any()));
    });

    test('a delete removes the row', () {
      groupCallback(
        payload(event: PostgresChangeEvent.delete, oldRecord: {'id': 'g1'}),
      );

      verify(() => groupBox.delete('g1')).called(1);
    });

    test('a delete with no usable id is ignored', () {
      groupCallback(
        payload(event: PostgresChangeEvent.delete, oldRecord: {'id': ''}),
      );
      groupCallback(
        payload(event: PostgresChangeEvent.delete, oldRecord: const {}),
      );

      verifyNever(() => groupBox.delete(any()));
    });

    test('an empty new record is ignored', () {
      groupCallback(payload(event: PostgresChangeEvent.update));

      verifyNever(() => groupBox.put(any(), any()));
    });

    test('a malformed record is swallowed rather than crashing', () {
      when(() => groupBox.get(any())).thenReturn(null);

      expect(
        () => groupCallback(
          payload(
            event: PostgresChangeEvent.update,
            newRecord: const {'id': 'g1', 'updated_at': 'not-a-date'},
          ),
        ),
        returnsNormally,
      );
      verifyNever(() => groupBox.put(any(), any()));
    });

    test('a stale server member is ignored', () {
      when(
        () => groupMemberBox.get('gm1'),
      ).thenReturn(member(updatedAt: DateTime.utc(2024, 12, 1)));

      memberCallback(
        payload(
          event: PostgresChangeEvent.update,
          table: 'group_members',
          newRecord: memberJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ),
      );

      verifyNever(() => groupMemberBox.put(any(), any()));
    });

    test('a newer server member overwrites the local copy', () {
      when(
        () => groupMemberBox.get('gm1'),
      ).thenReturn(member(updatedAt: DateTime.utc(2024, 1, 1)));

      memberCallback(
        payload(
          event: PostgresChangeEvent.update,
          table: 'group_members',
          newRecord: memberJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ),
      );

      verify(() => groupMemberBox.put('gm1', any())).called(1);
    });

    test('a new member for a known group does not refetch it', () async {
      when(() => groupMemberBox.get('gm1')).thenReturn(null);
      when(() => groupBox.containsKey('g1')).thenReturn(true);

      memberCallback(
        payload(
          event: PostgresChangeEvent.insert,
          table: 'group_members',
          newRecord: memberJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ),
      );
      await pumpEventQueue();

      verify(() => groupMemberBox.put('gm1', any())).called(1);
      verifyNever(() => client.from('groups'));
    });

    test('a new member for an unknown group fetches that group', () async {
      when(() => groupMemberBox.get('gm1')).thenReturn(null);
      when(() => groupBox.containsKey('g1')).thenReturn(false);
      final groupsBuilder = MockQueryBuilder();
      when(() => client.from('groups')).thenAnswer((_) => groupsBuilder);
      when(() => groupsBuilder.select()).thenAnswer(
        (_) => _FakeFilterBuilder<PostgrestList>([
          groupJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ]),
      );

      memberCallback(
        payload(
          event: PostgresChangeEvent.insert,
          table: 'group_members',
          newRecord: memberJson(updatedAt: '2024-06-01T00:00:00.000Z'),
        ),
      );
      await pumpEventQueue();

      // Without this backfill the member would point at a group the UI has
      // never heard of.
      verify(() => client.from('groups')).called(1);
    });

    test('a member delete with no usable id is ignored', () {
      memberCallback(
        payload(
          event: PostgresChangeEvent.delete,
          table: 'group_members',
          oldRecord: const {'id': 42},
        ),
      );

      verifyNever(() => groupMemberBox.delete(any()));
    });

    test('a member delete removes the row', () {
      memberCallback(
        payload(
          event: PostgresChangeEvent.delete,
          table: 'group_members',
          oldRecord: const {'id': 'gm1'},
        ),
      );

      verify(() => groupMemberBox.delete('gm1')).called(1);
    });

    test('initializing twice reuses the existing channels', () async {
      await service.initializeRealtime();

      // Subscribing again would duplicate every realtime frame.
      verify(() => client.channel('public:groups')).called(1);
      verify(() => client.channel('public:group_members')).called(1);
    });

    test('dispose tears both channels down', () {
      service.dispose();

      verify(() => client.removeChannel(any())).called(2);
      // A second dispose must not double-remove.
      service.dispose();
      verifyNever(() => client.removeChannel(any()));
    });
  });
}
