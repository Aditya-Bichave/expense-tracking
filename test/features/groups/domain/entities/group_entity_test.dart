import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tGroup = GroupEntity(
    id: '1',
    name: 'Test Group',
    type: GroupType.trip,
    currency: 'USD',
    createdBy: 'user1',
    createdAt: tDate,
    updatedAt: tDate,
    isArchived: false,
  );

  group('GroupEntity', () {
    test('props should contain all fields', () {
      expect(tGroup.props, ['1', 'Test Group', GroupType.trip, 'USD', null, 'user1', tDate, tDate, false]);
    });

    test('supports value equality', () {
      final tGroup2 = GroupEntity(
        id: '1',
        name: 'Test Group',
        type: GroupType.trip,
        currency: 'USD',
        createdBy: 'user1',
        createdAt: tDate,
        updatedAt: tDate,
        isArchived: false,
      );
      expect(tGroup, equals(tGroup2));
    });
  });
}
