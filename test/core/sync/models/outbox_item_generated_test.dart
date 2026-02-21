import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';

void main() {
  group('OutboxStatus enum', () {
    test('has all expected values', () {
      expect(OutboxStatus.values.length, 3);
      expect(OutboxStatus.values, contains(OutboxStatus.pending));
      expect(OutboxStatus.values, contains(OutboxStatus.sent));
      expect(OutboxStatus.values, contains(OutboxStatus.failed));
    });
  });

  group('OpType enum', () {
    test('has all expected values', () {
      expect(OpType.values.length, 3);
      expect(OpType.values, contains(OpType.create));
      expect(OpType.values, contains(OpType.update));
      expect(OpType.values, contains(OpType.delete));
    });
  });

  group('EntityType enum', () {
    test('has all expected values', () {
      expect(EntityType.values.length, 5);
      expect(EntityType.values, contains(EntityType.group));
      expect(EntityType.values, contains(EntityType.groupMember));
      expect(EntityType.values, contains(EntityType.groupExpense));
      expect(EntityType.values, contains(EntityType.settlement));
      expect(EntityType.values, contains(EntityType.invite));
    });
  });

  group('OutboxItem', () {
    final tItem = OutboxItem(
      id: '1',
      entityType: EntityType.group,
      opType: OpType.create,
      payloadJson: '{"key": "value"}',
      createdAt: DateTime(2023),
    );

    test('supports value access for required fields', () {
      expect(tItem.id, '1');
      expect(tItem.entityType, EntityType.group);
      expect(tItem.opType, OpType.create);
      expect(tItem.payloadJson, '{"key": "value"}');
      expect(tItem.createdAt, DateTime(2023));
    });

    test('has correct default values', () {
      expect(tItem.retryCount, 0);
      expect(tItem.status, OutboxStatus.pending);
      expect(tItem.lastError, null);
      expect(tItem.nextRetryAt, null);
    });

    test('can be created with all fields specified', () {
      final item = OutboxItem(
        id: '2',
        entityType: EntityType.groupMember,
        opType: OpType.update,
        payloadJson: '{"data": "test"}',
        createdAt: DateTime(2024),
        retryCount: 3,
        status: OutboxStatus.failed,
        lastError: 'Network error',
        nextRetryAt: DateTime(2024, 1, 2),
      );

      expect(item.id, '2');
      expect(item.entityType, EntityType.groupMember);
      expect(item.opType, OpType.update);
      expect(item.payloadJson, '{"data": "test"}');
      expect(item.createdAt, DateTime(2024));
      expect(item.retryCount, 3);
      expect(item.status, OutboxStatus.failed);
      expect(item.lastError, 'Network error');
      expect(item.nextRetryAt, DateTime(2024, 1, 2));
    });

    test('retryCount is mutable', () {
      final item = OutboxItem(
        id: '3',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime(2023),
      );
      expect(item.retryCount, 0);
      item.retryCount = 5;
      expect(item.retryCount, 5);
    });

    test('status is mutable', () {
      final item = OutboxItem(
        id: '4',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime(2023),
      );
      expect(item.status, OutboxStatus.pending);
      item.status = OutboxStatus.sent;
      expect(item.status, OutboxStatus.sent);
    });

    test('lastError is mutable', () {
      final item = OutboxItem(
        id: '5',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime(2023),
      );
      expect(item.lastError, null);
      item.lastError = 'Error message';
      expect(item.lastError, 'Error message');
    });

    test('nextRetryAt is mutable', () {
      final item = OutboxItem(
        id: '6',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime(2023),
      );
      expect(item.nextRetryAt, null);
      final retryTime = DateTime(2024, 1, 1);
      item.nextRetryAt = retryTime;
      expect(item.nextRetryAt, retryTime);
    });

    test('works with all EntityType values', () {
      for (final entityType in EntityType.values) {
        final item = OutboxItem(
          id: 'test',
          entityType: entityType,
          opType: OpType.create,
          payloadJson: '{}',
          createdAt: DateTime(2023),
        );
        expect(item.entityType, entityType);
      }
    });

    test('works with all OpType values', () {
      for (final opType in OpType.values) {
        final item = OutboxItem(
          id: 'test',
          entityType: EntityType.group,
          opType: opType,
          payloadJson: '{}',
          createdAt: DateTime(2023),
        );
        expect(item.opType, opType);
      }
    });

    test('works with all OutboxStatus values', () {
      for (final status in OutboxStatus.values) {
        final item = OutboxItem(
          id: 'test',
          entityType: EntityType.group,
          opType: OpType.create,
          payloadJson: '{}',
          createdAt: DateTime(2023),
          status: status,
        );
        expect(item.status, status);
      }
    });
  });
}