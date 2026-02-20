import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSupabaseQueryBuilder extends Mock implements SupabaseQueryBuilder {}

void main() {
  late SyncService service;
  late MockSupabaseClient mockClient;
  late MockOutboxRepository mockRepository;
  late MockSupabaseQueryBuilder mockQueryBuilder;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockRepository = MockOutboxRepository();
    mockQueryBuilder = MockSupabaseQueryBuilder();
    service = SyncService(mockClient, mockRepository);
  });

  group('SyncService', () {
    test('processOutbox should do nothing if no items', () async {
      when(() => mockRepository.getPendingItems()).thenReturn([]);

      await service.processOutbox();

      verify(() => mockRepository.getPendingItems()).called(1);
      verifyZeroInteractions(mockClient);
    });
  });
}
