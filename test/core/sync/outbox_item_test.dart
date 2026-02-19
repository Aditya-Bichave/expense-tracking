import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';

void main() {
  group('OutboxItem', () {
    test('should be instantiated correctly', () {
      final date = DateTime.now();
      final item = OutboxItem(
        id: '123',
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: date,
      );

      expect(item.id, '123');
      expect(item.entityType, EntityType.group);
      expect(item.opType, OpType.create);
      expect(item.payloadJson, '{}');
      expect(item.createdAt, date);
      expect(item.status, OutboxStatus.pending);
      expect(item.retryCount, 0);
    });
  });
}
