import 'dart:async';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class FakeOutboxItem extends Fake implements OutboxItem {}

// A fake builder that allows "await" to complete successfully
class FakePostgrestFilterBuilder extends Fake
    implements PostgrestFilterBuilder {
  @override
  Future<S> then<S>(
    FutureOr<S> Function(dynamic) onValue, {
    Function? onError,
  }) {
    // Simulate a successful completion with an empty list
    return Future.value([]).then((val) => onValue(val));
  }
}

void main() {
  late SyncService syncService;
  late MockOutboxRepository mockOutboxRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockSupabaseQueryBuilder mockQueryBuilder;
  late FakePostgrestFilterBuilder fakeFilterBuilder;

  setUpAll(() {
    registerFallbackValue(FakeOutboxItem());
  });

  setUp(() {
    mockOutboxRepository = MockOutboxRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    fakeFilterBuilder = FakePostgrestFilterBuilder();

    // Use thenAnswer to return the query builder
    when(
      () => mockSupabaseClient.from(any()),
    ).thenAnswer((_) => mockQueryBuilder);

    // Return our fake awaitable builder
    when(
      () => mockQueryBuilder.insert(any()),
    ).thenAnswer((_) => fakeFilterBuilder);
    when(
      () => mockQueryBuilder.update(any()),
    ).thenAnswer((_) => fakeFilterBuilder);
    when(() => mockQueryBuilder.delete()).thenAnswer((_) => fakeFilterBuilder);

    // Fix parameter order: SyncService(client, repo)
    syncService = SyncService(mockSupabaseClient, mockOutboxRepository);
  });

  group('processOutbox', () {
    final tItem = OutboxItem(
      id: '1',
      entityType: EntityType.group,
      opType: OpType.create,
      payloadJson: '{"name": "Test Group"}',
      createdAt: DateTime.now(),
    );

    test('should do nothing if no items', () async {
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([]);

      await syncService.processOutbox();

      verify(() => mockOutboxRepository.getPendingItems()).called(1);
      verifyNever(() => mockSupabaseClient.from(any()));
    });

    test('should attempt to process items', () async {
      when(() => mockOutboxRepository.getPendingItems()).thenReturn([tItem]);
      when(
        () => mockOutboxRepository.markAsSent(any()),
      ).thenAnswer((_) async {});

      // Now awaiting syncService.processOutbox() should succeed (the insert await will complete)
      await syncService.processOutbox();

      verify(() => mockOutboxRepository.getPendingItems()).called(1);
      verify(() => mockSupabaseClient.from('groups')).called(1);
      verify(() => mockQueryBuilder.insert(any())).called(1);
      verify(() => mockOutboxRepository.markAsSent(tItem)).called(1);
    });
  });
}
