import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';

void main() {
  final tDate = DateTime(2023, 1, 1);
  final tMember = GroupMember(
    id: '1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.admin,
    joinedAt: tDate,
  );

  group('GroupMember', () {
    test('props should contain all fields', () {
      expect(tMember.props, [
        '1',
        'g1',
        'u1',
        GroupRole.admin,
        tDate,
      ]);
    });

    test('supports value equality', () {
      final tMember2 = GroupMember(
        id: '1',
        groupId: 'g1',
        userId: 'u1',
        role: GroupRole.admin,
        joinedAt: tDate,
      );
      expect(tMember, equals(tMember2));
    });
  });
}
