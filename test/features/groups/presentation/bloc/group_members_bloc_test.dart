import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_event.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late GroupMembersBloc bloc;
  late MockGroupsRepository mockGroupsRepository;

  final joinedAt = DateTime(2024, 1, 1);
  final members = [
    GroupMember(
      id: '1',
      groupId: 'g1',
      userId: 'u1',
      role: GroupRole.admin,
      joinedAt: joinedAt,
      updatedAt: joinedAt,
    ),
  ];
  final updatedMembers = [
    GroupMember(
      id: '1',
      groupId: 'g1',
      userId: 'u1',
      role: GroupRole.viewer,
      joinedAt: joinedAt,
      updatedAt: joinedAt,
    ),
  ];

  GroupMembersState buildState({
    GroupMembersStatus status = GroupMembersStatus.loaded,
    GroupMembersAction action = GroupMembersAction.none,
    List<GroupMember> members = const <GroupMember>[],
    String? groupId = 'g1',
    String? message,
    String? inviteUrl,
  }) {
    return GroupMembersState(
      status: status,
      action: action,
      members: members,
      groupId: groupId,
      message: message,
      inviteUrl: inviteUrl,
    );
  }

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    bloc = GroupMembersBloc(mockGroupsRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('GroupMembersBloc', () {
    test('initial state is GroupMembersState.initial()', () {
      expect(bloc.state, GroupMembersState.initial());
    });

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits loading and then loaded members when LoadGroupMembers succeeds',
      setUp: () {
        when(
          () => mockGroupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => Right(members));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadGroupMembers('g1')),
      expect: () => [
        buildState(
          status: GroupMembersStatus.loading,
          members: const <GroupMember>[],
        ),
        buildState(members: members),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'preserves previously loaded members when a refresh fails',
      setUp: () {
        when(
          () => mockGroupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Error')));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(const LoadGroupMembers('g1')),
      expect: () => [
        buildState(status: GroupMembersStatus.loading, members: members),
        buildState(
          action: GroupMembersAction.failed,
          members: members,
          message: 'Error',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'preserves members while generating an invite',
      setUp: () {
        when(
          () => mockGroupsRepository.createInvite(
            any(),
            role: any(named: 'role'),
            expiryDays: any(named: 'expiryDays'),
            maxUses: any(named: 'maxUses'),
          ),
        ).thenAnswer((_) async => const Right('https://link.com'));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(const GenerateInviteLink(groupId: 'g1')),
      expect: () => [
        buildState(
          action: GroupMembersAction.generatingInvite,
          members: members,
        ),
        buildState(
          action: GroupMembersAction.inviteGenerated,
          members: members,
          message: 'Invite link copied to clipboard',
          inviteUrl: 'https://link.com',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits a failure action when invite generation fails',
      setUp: () {
        when(
          () => mockGroupsRepository.createInvite(
            any(),
            role: any(named: 'role'),
            expiryDays: any(named: 'expiryDays'),
            maxUses: any(named: 'maxUses'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Invite failed')));
      },
      build: () => bloc,
      seed: () => buildState(members: members, inviteUrl: 'stale-link'),
      act: (bloc) => bloc.add(const GenerateInviteLink(groupId: 'g1')),
      expect: () => [
        buildState(
          action: GroupMembersAction.generatingInvite,
          members: members,
        ),
        buildState(
          action: GroupMembersAction.failed,
          members: members,
          message: 'Invite failed',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'reloads members after a successful role change',
      setUp: () {
        when(
          () => mockGroupsRepository.updateMemberRole(any(), any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGroupsRepository.getGroupMembers('g1'),
        ).thenAnswer((_) async => Right(updatedMembers));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(
        const ChangeMemberRole(groupId: 'g1', userId: 'u1', newRole: 'viewer'),
      ),
      expect: () => [
        buildState(action: GroupMembersAction.updatingRole, members: members),
        buildState(
          action: GroupMembersAction.memberRoleUpdated,
          members: updatedMembers,
          message: 'Member role updated',
        ),
      ],
      verify: (_) {
        verify(
          () => mockGroupsRepository.updateMemberRole('g1', 'u1', 'viewer'),
        ).called(1);
        verify(() => mockGroupsRepository.getGroupMembers('g1')).called(1);
      },
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits a failure action when updating a member role fails',
      setUp: () {
        when(
          () => mockGroupsRepository.updateMemberRole(any(), any(), any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Role failed')));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(
        const ChangeMemberRole(groupId: 'g1', userId: 'u1', newRole: 'viewer'),
      ),
      expect: () => [
        buildState(action: GroupMembersAction.updatingRole, members: members),
        buildState(
          action: GroupMembersAction.failed,
          members: members,
          message: 'Role failed',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits a failure action when removing a member fails',
      setUp: () {
        when(
          () => mockGroupsRepository.removeMember(any(), any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Remove failed')));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(const KickMember(groupId: 'g1', userId: 'u1')),
      expect: () => [
        buildState(action: GroupMembersAction.removingMember, members: members),
        buildState(
          action: GroupMembersAction.failed,
          members: members,
          message: 'Remove failed',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'reloads members after a successful removal',
      setUp: () {
        when(
          () => mockGroupsRepository.removeMember(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGroupsRepository.getGroupMembers('g1'),
        ).thenAnswer((_) async => Right(updatedMembers));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(const KickMember(groupId: 'g1', userId: 'u1')),
      expect: () => [
        buildState(action: GroupMembersAction.removingMember, members: members),
        buildState(
          action: GroupMembersAction.memberRemoved,
          members: updatedMembers,
          message: 'Member removed',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits a failure action when reload after a successful update fails',
      setUp: () {
        when(
          () => mockGroupsRepository.updateMemberRole(any(), any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGroupsRepository.getGroupMembers('g1'),
        ).thenAnswer((_) async => const Left(CacheFailure('Reload failed')));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(
        const ChangeMemberRole(groupId: 'g1', userId: 'u1', newRole: 'viewer'),
      ),
      expect: () => [
        buildState(action: GroupMembersAction.updatingRole, members: members),
        buildState(
          action: GroupMembersAction.failed,
          members: members,
          message: 'Reload failed',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits leave actions while preserving the current member list',
      setUp: () {
        when(
          () => mockGroupsRepository.leaveGroup(any(), any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) =>
          bloc.add(const LeaveCurrentGroup(groupId: 'g1', userId: 'u1')),
      expect: () => [
        buildState(action: GroupMembersAction.leavingGroup, members: members),
        buildState(
          action: GroupMembersAction.leftGroup,
          members: members,
          message: 'You left the group',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits a failure action when leaving the group fails',
      setUp: () {
        when(
          () => mockGroupsRepository.leaveGroup(any(), any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Leave failed')));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) =>
          bloc.add(const LeaveCurrentGroup(groupId: 'g1', userId: 'u1')),
      expect: () => [
        buildState(action: GroupMembersAction.leavingGroup, members: members),
        buildState(
          action: GroupMembersAction.failed,
          members: members,
          message: 'Leave failed',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits delete success actions while preserving loaded detail state',
      setUp: () {
        when(
          () => mockGroupsRepository.deleteGroup(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(const DeleteCurrentGroup(groupId: 'g1')),
      expect: () => [
        buildState(action: GroupMembersAction.deletingGroup, members: members),
        buildState(
          action: GroupMembersAction.deletedGroup,
          members: members,
          message: 'Group deleted',
        ),
      ],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits a failure action when deleting the group fails',
      setUp: () {
        when(
          () => mockGroupsRepository.deleteGroup(any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Delete failed')));
      },
      build: () => bloc,
      seed: () => buildState(members: members),
      act: (bloc) => bloc.add(const DeleteCurrentGroup(groupId: 'g1')),
      expect: () => [
        buildState(action: GroupMembersAction.deletingGroup, members: members),
        buildState(
          action: GroupMembersAction.failed,
          members: members,
          message: 'Delete failed',
        ),
      ],
    );
  });
}
