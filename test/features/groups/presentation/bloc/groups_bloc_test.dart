import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/usecases/join_group.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups.dart';
import 'package:expense_tracker/features/groups/domain/usecases/watch_groups.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchGroups extends Mock implements WatchGroups {}
class MockSyncGroups extends Mock implements SyncGroups {}
class MockJoinGroup extends Mock implements JoinGroup {}

void main() {
  late GroupsBloc bloc;
  late MockWatchGroups mockWatchGroups;
  late MockSyncGroups mockSyncGroups;
  late MockJoinGroup mockJoinGroup;

  final tGroup = GroupEntity(
    id: '1',
    name: 'Group 1',
    type: GroupType.trip,
    currency: 'USD',
    createdBy: 'u1',
    createdAt: DateTime(2023, 1, 1),
    updatedAt: DateTime(2023, 1, 1),
    isArchived: false,
  );

  setUp(() {
    mockWatchGroups = MockWatchGroups();
    mockSyncGroups = MockSyncGroups();
    mockJoinGroup = MockJoinGroup();
    bloc = GroupsBloc(
      watchGroups: mockWatchGroups,
      syncGroups: mockSyncGroups,
      joinGroup: mockJoinGroup,
    );
  });

  group('GroupsBloc', () {
    test('initial state is GroupsInitial', () {
      expect(bloc.state, GroupsInitial());
    });

    blocTest<GroupsBloc, GroupsState>(
      'emits [Loading, Loaded] when LoadGroups is added',
      setUp: () {
        when(() => mockWatchGroups()).thenAnswer(
          (_) => Stream.value(Right([tGroup])),
        );
        when(() => mockSyncGroups()).thenAnswer(
          (_) async => const Right(null),
        );
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroups()),
      expect: () => [
        GroupsLoading(),
        GroupsLoaded([tGroup]),
      ],
      verify: (_) {
        verify(() => mockSyncGroups()).called(1);
      },
    );

    blocTest<GroupsBloc, GroupsState>(
      'emits [Loading, Error] when WatchGroups fails',
      setUp: () {
        when(() => mockWatchGroups()).thenAnswer(
          (_) => Stream.value(Left(CacheFailure('Error'))),
        );
        when(() => mockSyncGroups()).thenAnswer(
          (_) async => const Right(null),
        );
      },
      build: () => bloc,
      act: (bloc) => bloc.add(LoadGroups()),
      expect: () => [
        GroupsLoading(),
        GroupsError('Error'),
      ],
    );
  });
}
