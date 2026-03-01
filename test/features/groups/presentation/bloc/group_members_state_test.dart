import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';

void main() {
  group('GroupMembersState', () {
    test('GroupMembersInitial props should be empty', () {
      expect(GroupMembersInitial().props, []);
    });

    test('GroupMembersLoading props should be empty', () {
      expect(GroupMembersLoading().props, []);
    });

    test('GroupMembersLoaded props should contain members', () {
      final dateTime = DateTime.parse('2023-01-01T00:00:00.000Z');
      final members = <GroupMember>[
        GroupMember(
          id: '1',
          userId: 'u1',
          groupId: 'g1',
          role: GroupRole.admin,
          joinedAt: dateTime,
          updatedAt: dateTime,
        ),
      ];
      final state = GroupMembersLoaded(members);

      expect(state.props, [members]);
    });

    test('GroupMembersError props should contain message', () {
      const state = GroupMembersError('error message');

      expect(state.props, ['error message']);
    });

    test('GroupInviteGenerated props should contain url', () {
      const state = GroupInviteGenerated('http://invite.link');

      expect(state.props, ['http://invite.link']);
    });

    test('GroupInviteGenerationError props should contain message', () {
      const state = GroupInviteGenerationError('generation error');

      expect(state.props, ['generation error']);
    });
  });
}
