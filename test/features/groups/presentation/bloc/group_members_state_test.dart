import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_state.dart';

void main() {
  group('GroupMembersState', () {
    test('initial returns an empty idle state', () {
      final state = GroupMembersState.initial();

      expect(state.status, GroupMembersStatus.initial);
      expect(state.action, GroupMembersAction.none);
      expect(state.members, isEmpty);
      expect(state.isInitialLoadInProgress, isFalse);
      expect(state.hasBlockingError, isFalse);
      expect(state.isBusy, isFalse);
    });

    test(
      'copyWith clears transient message and invite fields without losing members',
      () {
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
        final state = GroupMembersState(
          status: GroupMembersStatus.loaded,
          action: GroupMembersAction.inviteGenerated,
          members: members,
          groupId: 'g1',
          message: 'Copied',
          inviteUrl: 'https://join',
        );
        final cleared = state.copyWith(
          action: GroupMembersAction.none,
          clearMessage: true,
          clearInviteUrl: true,
        );

        expect(cleared.members, members);
        expect(cleared.groupId, 'g1');
        expect(cleared.message, isNull);
        expect(cleared.inviteUrl, isNull);
        expect(cleared.action, GroupMembersAction.none);
      },
    );

    test('helper getters reflect blocking and busy states', () {
      final blockingError = GroupMembersState(
        status: GroupMembersStatus.error,
        action: GroupMembersAction.failed,
        members: const <GroupMember>[],
        groupId: 'g1',
        message: 'boom',
      );
      final busyState = GroupMembersState(
        status: GroupMembersStatus.loaded,
        action: GroupMembersAction.updatingRole,
        members: const <GroupMember>[],
        groupId: 'g1',
      );

      expect(blockingError.hasBlockingError, isTrue);
      expect(blockingError.isBusy, isFalse);
      expect(busyState.hasBlockingError, isFalse);
      expect(busyState.isBusy, isTrue);
    });
  });
}
