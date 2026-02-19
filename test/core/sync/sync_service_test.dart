import 'dart:async';
import 'dart:math';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockOutboxRepository extends Mock implements OutboxRepository {}
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder {
  final Object? error;
  FakePostgrestFilterBuilder({this.error});

  // Mocking the 'eq' method as it returns a builder too
  @override
  PostgrestFilterBuilder eq(String column, Object value) {
    return this;
  }

  @override
  Future<S> then<S>(FutureOr<S> Function(dynamic) onValue, {Function? onError}) {
     if (error != null) {
      // Delegate to a real failed Future so it handles onError callback signature correctly
      return Future.error(error!, StackTrace.current).then<S>((_) => onValue(null), onError: onError);
    }
    return Future.value([]).then((val) => onValue(val));
  }
}

void main() {
  late SyncService syncService;
  late MockOutboxRepository mockOutboxRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUpAll(() {
    registerFallbackValue(OutboxItem(
        id: 'fallback',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now()));
  });

  setUp(() {
    mockOutboxRepository = MockOutboxRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    syncService = SyncService(mockSupabaseClient, mockOutboxRepository);

    // Default success for failures handling
    when(() => mockOutboxRepository.markAsFailed(any(), any(), nextRetryAt: any(named: 'nextRetryAt')))
        .thenAnswer((_) async {});
  });

  group('processOutbox', () {
    test('should do nothing if no items', () async {
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([]);
      await syncService.processOutbox();
      verify(() => mockOutboxRepository.getPendingItems()).called(1);
      verifyNever(() => mockSupabaseClient.from(any()));
    });

    test('should succeed and mark as sent', () async {
      final item = OutboxItem(
        id: '1',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{"name": "Test Group"}',
        createdAt: DateTime.now(),
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockQueryBuilder);
      when(() => mockQueryBuilder.insert(any())).thenAnswer((_) => FakePostgrestFilterBuilder());
      when(() => mockOutboxRepository.markAsSent(any())).thenAnswer((_) async {});

      await syncService.processOutbox();

      verify(() => mockSupabaseClient.from('groups')).called(1);
      verify(() => mockQueryBuilder.insert(any())).called(1);
      verify(() => mockOutboxRepository.markAsSent(item)).called(1);
    });

    test('should retry with backoff on failure', () async {
      final item = OutboxItem(
        id: '2',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{"name": "Test Group"}',
        createdAt: DateTime.now(),
        retryCount: 0,
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockQueryBuilder);
      // Simulate failure
      when(() => mockQueryBuilder.insert(any())).thenAnswer((_) => FakePostgrestFilterBuilder(error: 'Network Error'));

      await syncService.processOutbox();

      verify(() => mockQueryBuilder.insert(any())).called(1);

      final captured = verify(() => mockOutboxRepository.markAsFailed(
        item,
        any(),
        nextRetryAt: captureAny(named: 'nextRetryAt')
      )).captured;

      final nextRetryAt = captured.first as DateTime;
      final now = DateTime.now();
      final diff = nextRetryAt.difference(now).inMilliseconds;

      expect(diff, greaterThanOrEqualTo(900));
      expect(diff, lessThan(3000));
    });

    test('should stop retrying after max retries', () async {
      final item = OutboxItem(
        id: '3',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{"name": "Test Group"}',
        createdAt: DateTime.now(),
        retryCount: 5, // Max retries
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);

      await syncService.processOutbox();

      // Should verify insert is NOT called
      verifyNever(() => mockSupabaseClient.from(any()));

      // Should mark as permanently failed (very future date)
       final captured = verify(() => mockOutboxRepository.markAsFailed(
        item,
        any(),
        nextRetryAt: captureAny(named: 'nextRetryAt')
      )).captured;

      final nextRetryAt = captured.first as DateTime;
      expect(nextRetryAt.year, 9999);
    });
  });

  group('Operations and Tables Coverage', () {
    // Helper to test combinations
    Future<void> verifyOperation(
      EntityType entityType,
      OpType opType,
      String expectedTable
    ) async {
      final item = OutboxItem(
        id: '123',
        entityType: entityType,
        opType: opType,
        payloadJson: '{"test": "val"}',
        createdAt: DateTime.now(),
      );

      when(() => mockOutboxRepository.getPendingItems()).thenReturn([item]);
      when(() => mockSupabaseClient.from(any())).thenAnswer((_) => mockQueryBuilder);

      final builder = FakePostgrestFilterBuilder();
      when(() => mockQueryBuilder.insert(any())).thenAnswer((_) => builder);
      when(() => mockQueryBuilder.update(any())).thenAnswer((_) => builder);
      when(() => mockQueryBuilder.delete()).thenAnswer((_) => builder);
      when(() => mockOutboxRepository.markAsSent(any())).thenAnswer((_) async {});

      await syncService.processOutbox();

      // Verify correct table selected
      verify(() => mockSupabaseClient.from(expectedTable)).called(1);

      // Verify correct operation called
      switch (opType) {
        case OpType.create:
          verify(() => mockQueryBuilder.insert({'test': 'val'})).called(1);
          break;
        case OpType.update:
          verify(() => mockQueryBuilder.update({'test': 'val'})).called(1);
          break;
        case OpType.delete:
          verify(() => mockQueryBuilder.delete()).called(1);
          break;
      }
    }

    test('should handle group create', () async {
      await verifyOperation(EntityType.group, OpType.create, 'groups');
    });

    test('should handle groupMember update', () async {
      await verifyOperation(EntityType.groupMember, OpType.update, 'group_members');
    });

    test('should handle groupExpense delete', () async {
      await verifyOperation(EntityType.groupExpense, OpType.delete, 'expenses');
    });

    test('should handle settlement create', () async {
      await verifyOperation(EntityType.settlement, OpType.create, 'settlements');
    });

    test('should handle invite create', () async {
      await verifyOperation(EntityType.invite, OpType.create, 'invites');
    });
  });
}
