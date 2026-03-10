import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GroupMembersEvent', () {
    test('LoadGroupMembers supports value comparisons', () {
      expect(const LoadGroupMembers('1'), equals(const LoadGroupMembers('1')));
      expect(
        const LoadGroupMembers('1'),
        isNot(equals(const LoadGroupMembers('2'))),
      );
    });

    test('GenerateInviteLink supports value comparisons', () {
      expect(
        const GenerateInviteLink(
          groupId: '1',
          role: 'admin',
          expiryDays: 10,
          maxUses: 5,
        ),
        equals(
          const GenerateInviteLink(
            groupId: '1',
            role: 'admin',
            expiryDays: 10,
            maxUses: 5,
          ),
        ),
      );
      expect(
        const GenerateInviteLink(groupId: '1'),
        equals(
          const GenerateInviteLink(
            groupId: '1',
            role: 'member',
            expiryDays: 7,
            maxUses: 0,
          ),
        ),
      );
      expect(
        const GenerateInviteLink(groupId: '1'),
        isNot(equals(const GenerateInviteLink(groupId: '2'))),
      );
    });

    test('ChangeMemberRole supports value comparisons', () {
      expect(
        const ChangeMemberRole(groupId: '1', userId: 'user1', newRole: 'admin'),
        equals(
          const ChangeMemberRole(
            groupId: '1',
            userId: 'user1',
            newRole: 'admin',
          ),
        ),
      );
      expect(
        const ChangeMemberRole(groupId: '1', userId: 'user1', newRole: 'admin'),
        isNot(
          equals(
            const ChangeMemberRole(
              groupId: '2',
              userId: 'user1',
              newRole: 'admin',
            ),
          ),
        ),
      );
    });

    test('KickMember supports value comparisons', () {
      expect(
        const KickMember(groupId: '1', userId: 'user1'),
        equals(const KickMember(groupId: '1', userId: 'user1')),
      );
      expect(
        const KickMember(groupId: '1', userId: 'user1'),
        isNot(equals(const KickMember(groupId: '2', userId: 'user1'))),
      );
    });
  });
}
