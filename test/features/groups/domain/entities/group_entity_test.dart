import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tGroup = GroupEntity(
    id: '1',
    name: 'Test Group',
    createdBy: 'user1',
    createdAt: tDate,
    updatedAt: tDate,
  );

  group('GroupEntity', () {
    test('props should contain all fields', () {
      expect(tGroup.props, [
        '1',
        'Test Group',
        'user1',
        tDate,
        tDate,
      ]);
    });

    test('supports value equality', () {
      final tGroup2 = GroupEntity(
        id: '1',
        name: 'Test Group',
        createdBy: 'user1',
        createdAt: tDate,
        updatedAt: tDate,
      );
      expect(tGroup, equals(tGroup2));
    });
  });
}
