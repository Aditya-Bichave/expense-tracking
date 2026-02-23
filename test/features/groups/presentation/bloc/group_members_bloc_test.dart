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
      ),
    ];

    blocTest<GroupMembersBloc, GroupMembersState>(
      'emits [GroupMembersLoading, GroupMembersLoaded] when LoadGroupMembers is added and successful',
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
  });
}
