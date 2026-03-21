import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:expense_tracker/features/groups/domain/usecases/sync_groups.dart';
import 'package:expense_tracker/features/groups/domain/usecases/watch_groups.dart';
import 'package:expense_tracker/features/groups/presentation/bloc/groups_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchGroups extends Mock implements WatchGroups {}

class MockSyncGroups extends Mock implements SyncGroups {}

void main() {
  late MockWatchGroups mockWatchGroups;
  late MockSyncGroups mockSyncGroups;

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
  });

  GroupsBloc buildBloc() =>
      GroupsBloc(watchGroups: mockWatchGroups, syncGroups: mockSyncGroups);

  group('GroupsBloc', () {
    test('initial state is GroupsInitial', () {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const GroupsInitial());
    });

    blocTest<GroupsBloc, GroupsState>(
      'emits [Loading, Loaded] when LoadGroups is added',
      setUp: () {
        when(
          () => mockWatchGroups(),
        ).thenAnswer((_) => Stream.value(Right([tGroup])));
        when(() => mockSyncGroups()).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadGroups()),
      expect: () => [
        const GroupsLoading(),
        GroupsLoaded([tGroup]),
      ],
      verify: (_) {
        verify(() => mockWatchGroups()).called(1);
        verify(() => mockSyncGroups()).called(1);
      },
    );

    blocTest<GroupsBloc, GroupsState>(
      'does not resubscribe when LoadGroups is added again',
      setUp: () {
        when(
          () => mockWatchGroups(),
        ).thenAnswer((_) => Stream.value(Right([tGroup])));
        when(() => mockSyncGroups()).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const LoadGroups());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const LoadGroups());
      },
      expect: () => [
        const GroupsLoading(),
        GroupsLoaded([tGroup]),
      ],
      verify: (_) {
        verify(() => mockWatchGroups()).called(1);
        verify(() => mockSyncGroups()).called(1);
      },
    );

    blocTest<GroupsBloc, GroupsState>(
      'refreshes via sync without re-emitting loading once data is loaded',
      setUp: () {
        when(
          () => mockWatchGroups(),
        ).thenAnswer((_) => Stream.value(Right([tGroup])));
        when(() => mockSyncGroups()).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) async {
        bloc.add(const LoadGroups());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const RefreshGroups(showLoading: true));
      },
      expect: () => [
        const GroupsLoading(),
        GroupsLoaded([tGroup]),
      ],
      verify: (_) {
        verify(() => mockWatchGroups()).called(1);
        verify(() => mockSyncGroups()).called(2);
      },
    );

    blocTest<GroupsBloc, GroupsState>(
      'emits [Loading, Error] when watchGroups returns a failure result',
      setUp: () {
        when(
          () => mockWatchGroups(),
        ).thenAnswer((_) => Stream.value(const Left(CacheFailure('Error'))));
        when(() => mockSyncGroups()).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadGroups()),
      expect: () => [const GroupsLoading(), const GroupsError('Error')],
    );

    blocTest<GroupsBloc, GroupsState>(
      'refresh before initial load delegates to LoadGroups and syncs once',
      setUp: () {
        when(
          () => mockWatchGroups(),
        ).thenAnswer((_) => Stream.value(Right([tGroup])));
        when(() => mockSyncGroups()).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const RefreshGroups()),
      expect: () => [
        const GroupsLoading(),
        GroupsLoaded([tGroup]),
      ],
      verify: (_) {
        verify(() => mockWatchGroups()).called(1);
        verify(() => mockSyncGroups()).called(1);
      },
    );

    blocTest<GroupsBloc, GroupsState>(
      'emits an error when the watch stream throws',
      setUp: () {
        when(() => mockWatchGroups()).thenAnswer(
          (_) => Stream<Either<Failure, List<GroupEntity>>>.error(
            Exception('stream exploded'),
          ),
        );
        when(() => mockSyncGroups()).thenAnswer((_) async => const Right(null));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadGroups()),
      expect: () => [
        const GroupsLoading(),
        const GroupsError('Exception: stream exploded'),
      ],
    );

    blocTest<GroupsBloc, GroupsState>(
      'keeps the stream subscription active even if sync throws',
      setUp: () {
        when(
          () => mockWatchGroups(),
        ).thenAnswer((_) => Stream.value(Right([tGroup])));
        when(() => mockSyncGroups()).thenAnswer((_) => Future.error(Exception('sync boom')));
      },
      build: buildBloc,
      act: (bloc) => bloc.add(const LoadGroups()),
      expect: () => [
        const GroupsLoading(),
        GroupsLoaded([tGroup]),
      ],
      verify: (_) {
        verify(() => mockWatchGroups()).called(1);
        verify(() => mockSyncGroups()).called(1);
      },
    );
  });
}
