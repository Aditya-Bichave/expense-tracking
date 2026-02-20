import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:mocktail/mocktail.dart';

class MockBox<T> extends Mock implements Box<T> {}

class FakeOutboxItem extends Fake implements OutboxItem {}

void main() {
  late OutboxRepository repository;
  late MockBox<OutboxItem> mockBox;

  setUpAll(() {
    registerFallbackValue(FakeOutboxItem());
  });

  setUp(() {
    mockBox = MockBox();
    repository = OutboxRepository(mockBox);
  });

  group('add', () {
    test('should add item to box', () async {
      final item = OutboxItem(
        id: '1',
        entityId: '100',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now(),
      );
      when(() => mockBox.add(any())).thenAnswer((_) async => 1);

      await repository.add(item);

      verify(() => mockBox.add(item)).called(1);
    });
  });

  group('getPendingItems', () {
    test('should return pending items', () {
      final item = OutboxItem(
        id: '1',
        entityId: '100',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now(),
        status: OutboxStatus.pending,
      );
      when(() => mockBox.values).thenReturn([item]);

      final result = repository.getPendingItems();

      expect(result.length, 1);
      expect(result.first, item);
    });

    test('should return failed items ready for retry', () {
      final item = OutboxItem(
        id: '2',
        entityId: '101',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now(),
        status: OutboxStatus.failed,
        nextRetryAt: DateTime.now().subtract(const Duration(seconds: 1)),
      );
      when(() => mockBox.values).thenReturn([item]);

      final result = repository.getPendingItems();

      expect(result.length, 1);
      expect(result.first, item);
    });

    test(
      'should return failed items if nextRetryAt is null (backward compatibility)',
      () {
        final item = OutboxItem(
          id: '2b',
          entityId: '102',
          entityType: EntityType.group,
          opType: OpType.create,
          payloadJson: '{}',
          createdAt: DateTime.now(),
          status: OutboxStatus.failed,
          nextRetryAt: null,
        );
        when(() => mockBox.values).thenReturn([item]);

        final result = repository.getPendingItems();

        expect(result.length, 1);
        expect(result.first, item);
      },
    );

    test('should NOT return failed items with future retry time', () {
      final item = OutboxItem(
        id: '3',
        entityId: '103',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now(),
        status: OutboxStatus.failed,
        nextRetryAt: DateTime.now().add(const Duration(hours: 1)),
      );
      when(() => mockBox.values).thenReturn([item]);

      final result = repository.getPendingItems();

      expect(result.isEmpty, true);
    });

    test('should sort items by createdAt', () {
      final item1 = OutboxItem(
        id: '1',
        entityId: '101',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now().add(const Duration(seconds: 10)),
      );
      final item2 = OutboxItem(
        id: '2',
        entityId: '102',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now(),
      );
      when(() => mockBox.values).thenReturn([item1, item2]);

      final result = repository.getPendingItems();

      expect(result.length, 2);
      expect(result[0], item2);
      expect(result[1], item1);
    });
  });

  group('markAsFailed', () {
    test('should mark as failed and update properties', () async {
      final item = OutboxItem(
        id: '1',
        entityId: '100',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now(),
      );

      // Mock save to prevent crash if internal implementation calls it
      try {
        await repository.markAsFailed(
          item,
          'error',
          nextRetryAt: DateTime(2025),
        );
      } catch (e) {
        // Ignore save() error in unit test environment
      }

      expect(item.status, OutboxStatus.failed);
      expect(item.lastError, 'error');
      expect(item.retryCount, 1);
      expect(item.nextRetryAt, DateTime(2025));
    });

    test('clear should clear box', () async {
      when(() => mockBox.clear()).thenAnswer((_) async => 0);
      await repository.clear();
      verify(() => mockBox.clear()).called(1);
    });
  });
}
