import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsRepository extends Mock implements GroupsRepository {}

class FakeGroupEntity extends Fake implements GroupEntity {}

void main() {
  late GroupsBloc bloc;
  late MockGroupsRepository mockRepository;

  final tGroup = GroupEntity(
    id: '1',
    name: 'Group 1',
    createdBy: 'u1',
    createdAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2023, 1, 1),
  );

  setUpAll(() {
    registerFallbackValue(FakeGroupEntity());
  });

  setUp(() {
    mockRepository = MockGroupsRepository();
    bloc = GroupsBloc(mockRepository);
  });

  group('GroupsBloc', () {
    test('initial state is GroupsInitial', () {
      expect(bloc.state, GroupsInitial());
    });

    blocTest<GroupsBloc, GroupsState>(
      'emits [Loading, Loaded] when LoadGroups is added',
      setUp: () {
        when(
          () => mockRepository.getGroups(),
        ).thenAnswer((_) async => Right([tGroup]));
        when(
          () => mockRepository.syncGroups(),
        ).thenAnswer((_) => Completer<Either<Failure, void>>().future);
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroups()),
      expect: () => [
        GroupsLoading(),
        GroupsLoaded([tGroup]),
      ],
    );

    blocTest<GroupsBloc, GroupsState>(
      'emits [GroupsError] when CreateGroupRequested fails',
      setUp: () {
        when(
          () => mockRepository.createGroup(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Error')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(CreateGroupRequested('New Group', 'u1')),
      expect: () => [GroupsError('Error')],
    );

    blocTest<GroupsBloc, GroupsState>(
      'emits [Loading, GroupsError] when JoinGroupRequested fails',
      setUp: () {
        when(
          () => mockRepository.acceptInvite(any()),
        ).thenAnswer((_) async => Left(ServerFailure('Invalid token')));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(JoinGroupRequested('token')),
      expect: () => [GroupsLoading(), GroupsError('Invalid token')],
    );
  });
}
