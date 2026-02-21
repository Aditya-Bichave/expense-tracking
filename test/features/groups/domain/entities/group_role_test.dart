import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';

void main() {
  group('GroupRole', () {
    test('value should return enum name', () {
      expect(GroupRole.admin.value, 'admin');
      expect(GroupRole.member.value, 'member');
      expect(GroupRole.viewer.value, 'viewer');
    });

    test('fromValue should return correct enum', () {
      expect(GroupRole.fromValue('admin'), GroupRole.admin);
      expect(GroupRole.fromValue('member'), GroupRole.member);
      expect(GroupRole.fromValue('viewer'), GroupRole.viewer);
    });

    test('fromValue should return member for unknown string', () {
      expect(GroupRole.fromValue('unknown'), GroupRole.member);
    });
  });
}
