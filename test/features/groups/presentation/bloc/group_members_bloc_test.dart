import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/group_members_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

void main() {
  late GroupMembersBloc bloc;
  late MockGroupsRepository mockGroupsRepository;

  setUp(() {
    mockGroupsRepository = MockGroupsRepository();
    bloc = GroupMembersBloc(mockGroupsRepository);
  });

  tearDown(() {
    bloc.close();
  });

  group('GroupMembersBloc', () {
    test('initial state is GroupMembersInitial', () {
      expect(bloc.state, GroupMembersInitial());
    });

    final members = [
      GroupMember(
        id: '1',
        groupId: 'g1',
        userId: 'u1',
        role: GroupRole.admin,
        joinedAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // LoadGroupMembers
    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [GroupMembersLoading, GroupMembersLoaded] when LoadGroupMembers is successful',
      setUp: () {
        when(
          () => mockGroupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => Right(members));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadGroupMembers('g1')),
      expect: () => [GroupMembersLoading(), GroupMembersLoaded(members)],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [GroupMembersLoading, GroupMembersError] when LoadGroupMembers fails',
      setUp: () {
        when(
          () => mockGroupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Error')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const LoadGroupMembers('g1')),
      expect: () => [GroupMembersLoading(), const GroupMembersError('Error')],
    );

    // GenerateInviteLink
    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [GroupInviteGenerated] when GenerateInviteLink is successful',
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
      act: (bloc) => bloc.add(const GenerateInviteLink(groupId: 'g1')),
      expect: () => [const GroupInviteGenerated('https://link.com')],
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [GroupInviteGenerationError] when GenerateInviteLink fails',
      setUp: () {
        when(
          () => mockGroupsRepository.createInvite(
            any(),
            role: any(named: 'role'),
            expiryDays: any(named: 'expiryDays'),
            maxUses: any(named: 'maxUses'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure('Failed')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const GenerateInviteLink(groupId: 'g1')),
      expect: () => [const GroupInviteGenerationError('Failed')],
    );

    // ChangeMemberRole
    blocTest<GroupMembersBloc, GroupMembersState>(
      'calls updateMemberRole and reloads on success',
      setUp: () {
        when(
          () => mockGroupsRepository.updateMemberRole(any(), any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGroupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => Right(members));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        const ChangeMemberRole(groupId: 'g1', userId: 'u1', newRole: 'member'),
      ),
      verify: (_) {
        verify(
          () => mockGroupsRepository.updateMemberRole('g1', 'u1', 'member'),
        ).called(1);
        verify(() => mockGroupsRepository.getGroupMembers('g1')).called(1);
      },
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits GroupMembersError on ChangeMemberRole failure',
      setUp: () {
        when(
          () => mockGroupsRepository.updateMemberRole(any(), any(), any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Update failed')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(
        const ChangeMemberRole(groupId: 'g1', userId: 'u1', newRole: 'member'),
      ),
      expect: () => [const GroupMembersError('Update failed')],
    );

    // KickMember
    blocTest<GroupMembersBloc, GroupMembersState>(
      'calls removeMember and reloads on success',
      setUp: () {
        when(
          () => mockGroupsRepository.removeMember(any(), any()),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockGroupsRepository.getGroupMembers(any()),
        ).thenAnswer((_) async => Right(members));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const KickMember(groupId: 'g1', userId: 'u1')),
      verify: (_) {
        verify(() => mockGroupsRepository.removeMember('g1', 'u1')).called(1);
        verify(() => mockGroupsRepository.getGroupMembers('g1')).called(1);
      },
    );

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits GroupMembersError on KickMember failure',
      setUp: () {
        when(
          () => mockGroupsRepository.removeMember(any(), any()),
        ).thenAnswer((_) async => const Left(ServerFailure('Remove failed')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(const KickMember(groupId: 'g1', userId: 'u1')),
      expect: () => [const GroupMembersError('Remove failed')],
    );
  });
}
