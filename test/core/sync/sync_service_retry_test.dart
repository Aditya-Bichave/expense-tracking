import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock implements PostgrestFilterBuilder {}

class FakeOutboxItem extends Fake implements OutboxItem {}

void main() {
  late SyncService service;
  late MockSupabaseClient mockClient;
  late MockOutboxRepository mockRepository;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUpAll(() {
    registerFallbackValue(FakeOutboxItem());
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockRepository = MockOutboxRepository();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    service = SyncService(mockClient, mockRepository);
  });

  group('SyncService Retry Logic', () {
    final tItem = OutboxItem(
      id: '1',
      entityId: '100',
      entityType: EntityType.group,
      opType: OpType.create,
      payloadJson: '{"name": "Test Group"}',
      createdAt: DateTime.now(),
    );

    test('should increment retry count on failure', () async {
      when(() => mockRepository.getPendingItems()).thenReturn([tItem]);

      when(() => mockClient.from(any())).thenAnswer((_) => mockQueryBuilder);
      when(
        () => mockQueryBuilder.insert(any()),
      ).thenThrow(Exception('Network Error'));

      when(
        () => mockRepository.markAsFailed(any(), any()),
      ).thenAnswer((_) async {});

      await service.processOutbox();

      expect(tItem.retryCount, 1);
      verify(() => mockRepository.markAsFailed(any(), any())).called(1);
    });

    test('should skip item if max retries exceeded', () async {
      tItem.retryCount = 5; // SyncService.maxRetries
      when(() => mockRepository.getPendingItems()).thenReturn([tItem]);

      await service.processOutbox();

      verifyNever(() => mockClient.from(any()));
    });
  });
}
