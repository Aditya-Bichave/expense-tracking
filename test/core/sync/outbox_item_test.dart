import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OutboxItem', () {
    test('should be instantiated correctly', () {
      final item = OutboxItem(
        id: '1',
        entityId: '100', // Added entityId
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: '{}',
        createdAt: DateTime.now(),
      );

      expect(item.id, '1');
      expect(item.entityId, '100');
      expect(item.entityType, EntityType.group);
      expect(item.opType, OpType.create);
      expect(item.status, OutboxStatus.pending);
    });
  });
}
