import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';

void main() {
  final tItem = OutboxItem(
    id: '1',
    entityType: EntityType.group, // Use Enum
    opType: OpType.create, // Use Enum
    payloadJson: '{"key": "value"}', // Use String
    createdAt: DateTime(2023),
  );

  test('supports value access', () {
    expect(tItem.id, '1');
    expect(tItem.entityType, EntityType.group);
    expect(tItem.opType, OpType.create);
    expect(tItem.payloadJson, '{"key": "value"}');
  });
}
