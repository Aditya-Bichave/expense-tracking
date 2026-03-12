import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/repositories/groups_repository_impl.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsLocalDataSource extends Mock implements GroupsLocalDataSource {}

class MockGroupsRemoteDataSource extends Mock
    implements GroupsRemoteDataSource {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockConnectivity extends Mock implements Connectivity {}

class MockGroupExpensesLocalDataSource extends Mock
    implements GroupExpensesLocalDataSource {}

class FakeSyncMutationModel extends Fake implements SyncMutationModel {}

class FakeGroupModel extends Fake implements GroupModel {}

void main() {
  late GroupsRepositoryImpl repository;
  late MockGroupsLocalDataSource mockLocalDataSource;
  late MockGroupsRemoteDataSource mockRemoteDataSource;
  late MockOutboxRepository mockOutboxRepository;
  late MockSyncService mockSyncService;
  late MockConnectivity mockConnectivity;
  late MockGroupExpensesLocalDataSource mockGroupExpensesLocalDataSource;

  final now = DateTime(2024, 1, 1);
  final tGroup = GroupEntity(
    id: 'g1',
    name: 'Test Group',
    type: GroupType.trip,
    currency: 'USD',
    createdBy: 'user1',
    createdAt: now,
    updatedAt: now,
    photoUrl: 'https://example.com/group.jpg',
    isArchived: false,
  );

  final tGroupModel = GroupModel.fromEntity(tGroup);

  setUpAll(() {
    registerFallbackValue(FakeSyncMutationModel());
    registerFallbackValue(FakeGroupModel());
    registerFallbackValue(<GroupModel>[]);
    registerFallbackValue(<GroupMemberModel>[]);
  });

  setUp(() {
    mockLocalDataSource = MockGroupsLocalDataSource();
    mockRemoteDataSource = MockGroupsRemoteDataSource();
    mockOutboxRepository = MockOutboxRepository();
    mockSyncService = MockSyncService();
    mockConnectivity = MockConnectivity();
    mockGroupExpensesLocalDataSource = MockGroupExpensesLocalDataSource();

    repository = GroupsRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      outboxRepository: mockOutboxRepository,
      syncService: mockSyncService,
      connectivity: mockConnectivity,
      groupExpensesLocalDataSource: mockGroupExpensesLocalDataSource,
    );
  });

  group('createGroup', () {
    test(
      'saves locally, creates a local admin member, queues an outbox mutation, and triggers sync when online',
      () async {
        when(
          () => mockLocalDataSource.saveGroup(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.saveGroupMembers(any()),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockSyncService.processOutbox()).thenAnswer((_) async {});

        final result = await repository.createGroup(tGroup);

        expect(result.isRight(), isTrue);
        verify(() => mockLocalDataSource.saveGroup(any())).called(1);

        final savedMembers =
            verify(
                  () => mockLocalDataSource.saveGroupMembers(captureAny()),
                ).captured.single
                as List<GroupMemberModel>;
        expect(savedMembers, hasLength(1));
        expect(savedMembers.single.groupId, tGroup.id);
        expect(savedMembers.single.userId, tGroup.createdBy);
        expect(savedMembers.single.roleValue, 'admin');

        final mutation =
            verify(() => mockOutboxRepository.add(captureAny())).captured.single
                as SyncMutationModel;
        expect(mutation.table, 'groups');
        expect(mutation.operation, OpType.create);
        expect(mutation.payload, containsPair('photo_url', tGroup.photoUrl));
        expect(mutation.payload, containsPair('is_archived', false));
        verify(() => mockSyncService.processOutbox()).called(1);
      },
    );

    test('returns CacheFailure when a local write fails', () async {
      when(
        () => mockLocalDataSource.saveGroup(any()),
      ).thenThrow(Exception('disk exploded'));

      final result = await repository.createGroup(tGroup);

      expect(result.isLeft(), isTrue);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<CacheFailure>(),
      );
    });
  });

  group('updateGroup', () {
    test('saves locally and queues a snake_case update mutation', () async {
      final updatedGroup = tGroup.copyWith(
        name: 'Edited Group',
        currency: 'INR',
      );

      when(() => mockLocalDataSource.saveGroup(any())).thenAnswer((_) async {});
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await repository.updateGroup(updatedGroup);

      expect(result.isRight(), isTrue);
      final mutation =
          verify(() => mockOutboxRepository.add(captureAny())).captured.single
              as SyncMutationModel;
      expect(mutation.operation, OpType.update);
      expect(mutation.payload, containsPair('name', 'Edited Group'));
      expect(mutation.payload, containsPair('currency', 'INR'));
      expect(mutation.payload, containsPair('photo_url', tGroup.photoUrl));
      verifyNever(() => mockSyncService.processOutbox());
    });
  });

  group('deleteGroup', () {
    test('cleans local group state and queues a delete mutation', () async {
      when(
        () => mockLocalDataSource.deleteGroup(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockLocalDataSource.deleteGroupMembers(any()),
      ).thenAnswer((_) async {});
      when(
        () => mockGroupExpensesLocalDataSource.deleteExpensesForGroup(any()),
      ).thenAnswer((_) async {});
      when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await repository.deleteGroup('g1');

      expect(result.isRight(), isTrue);
      verify(() => mockLocalDataSource.deleteGroup('g1')).called(1);
      verify(() => mockLocalDataSource.deleteGroupMembers('g1')).called(1);
      verify(
        () => mockGroupExpensesLocalDataSource.deleteExpensesForGroup('g1'),
      ).called(1);

      final mutation =
          verify(() => mockOutboxRepository.add(captureAny())).captured.single
              as SyncMutationModel;
      expect(mutation.table, 'groups');
      expect(mutation.operation, OpType.delete);
      expect(mutation.payload, {'id': 'g1'});
    });
  });

  group('leaveGroup', () {
    test(
      'cleans local state and queues a composite member delete mutation',
      () async {
        when(
          () => mockLocalDataSource.deleteGroup(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.deleteGroupMembers(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockGroupExpensesLocalDataSource.deleteExpensesForGroup(any()),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.none]);

        final result = await repository.leaveGroup('g1', 'user1');

        expect(result.isRight(), isTrue);
        final mutation =
            verify(() => mockOutboxRepository.add(captureAny())).captured.single
                as SyncMutationModel;
        expect(mutation.table, 'group_members');
        expect(mutation.operation, OpType.delete);
        expect(mutation.id, 'g1:user1');
        expect(mutation.payload, {'group_id': 'g1', 'user_id': 'user1'});
      },
    );
  });

  group('getGroups and watchGroups', () {
    test('returns groups sorted by updatedAt descending', () async {
      final newerGroup = GroupModel.fromEntity(
        tGroup.copyWith(
          id: 'g2',
          name: 'Newest',
          updatedAt: now.add(const Duration(days: 1)),
        ),
      );
      when(
        () => mockLocalDataSource.getGroups(),
      ).thenReturn([tGroupModel, newerGroup]);

      final result = await repository.getGroups();

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected groups'),
        (groups) => expect(groups.map((group) => group.id), ['g2', 'g1']),
      );
    });

    test('maps local stream values into sorted group entities', () async {
      when(
        () => mockLocalDataSource.watchGroups(),
      ).thenAnswer((_) => Stream.value([tGroupModel]));

      expect(
        repository.watchGroups(),
        emits(
          predicate<Either<Failure, List<GroupEntity>>>(
            (result) =>
                result.fold((_) => false, (groups) => groups.single.id == 'g1'),
          ),
        ),
      );
    });
  });

  group('refreshGroupsFromServer', () {
    test(
      'removes stale groups and cleans related members and expenses',
      () async {
        final staleGroup = GroupModel(
          id: 'stale',
          name: 'Stale Group',
          createdBy: 'user2',
          createdAt: now,
          updatedAt: now,
          typeValue: 'home',
          currency: 'INR',
        );

        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(
          () => mockRemoteDataSource.getGroups(),
        ).thenAnswer((_) async => [tGroupModel]);
        when(
          () => mockLocalDataSource.saveGroups(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.getGroups(),
        ).thenReturn([tGroupModel, staleGroup]);
        when(
          () => mockLocalDataSource.deleteGroups(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockLocalDataSource.deleteGroupMembers(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockGroupExpensesLocalDataSource.deleteExpensesForGroup(any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRemoteDataSource.getGroupMembers('g1'),
        ).thenAnswer((_) async => []);
        when(
          () => mockLocalDataSource.saveGroupMembers(any()),
        ).thenAnswer((_) async {});
        when(() => mockLocalDataSource.getGroupMembers('g1')).thenReturn([]);

        final result = await repository.refreshGroupsFromServer();

        expect(result.isRight(), isTrue);
        verify(() => mockLocalDataSource.deleteGroups(['stale'])).called(1);
        verify(() => mockLocalDataSource.deleteGroupMembers('stale')).called(1);
        verify(
          () =>
              mockGroupExpensesLocalDataSource.deleteExpensesForGroup('stale'),
        ).called(1);
        verify(() => mockRemoteDataSource.getGroupMembers('g1')).called(1);
      },
    );

    test('returns Right(null) without remote work when offline', () async {
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      final result = await repository.refreshGroupsFromServer();

      expect(result, const Right(null));
      verifyNever(() => mockRemoteDataSource.getGroups());
    });
  });

  group('remote invite and member actions', () {
    test(
      'createInvite forwards the full contract to the remote data source',
      () async {
        when(
          () => mockRemoteDataSource.createInvite(
            any(),
            role: any(named: 'role'),
            expiryDays: any(named: 'expiryDays'),
            maxUses: any(named: 'maxUses'),
          ),
        ).thenAnswer((_) async => 'https://spendos.app/join?token=abc');

        final result = await repository.createInvite(
          'g1',
          role: 'viewer',
          expiryDays: 3,
          maxUses: 1,
        );

        expect(result, const Right('https://spendos.app/join?token=abc'));
        verify(
          () => mockRemoteDataSource.createInvite(
            'g1',
            role: 'viewer',
            expiryDays: 3,
            maxUses: 1,
          ),
        ).called(1);
      },
    );

    test('acceptInvite returns the remote join payload', () async {
      when(
        () => mockRemoteDataSource.acceptInvite('token'),
      ).thenAnswer((_) async => {'group_id': 'g1', 'group_name': 'Trip'});

      final result = await repository.acceptInvite('token');

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('expected a successful join payload'),
        (payload) => expect(payload['group_name'], 'Trip'),
      );
    });

    test('updateMemberRole refreshes members after success', () async {
      when(
        () => mockRemoteDataSource.updateMemberRole('g1', 'user1', 'viewer'),
      ).thenAnswer((_) async {});
      when(
        () => mockRemoteDataSource.getGroupMembers('g1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveGroupMembers(any()),
      ).thenAnswer((_) async {});
      when(() => mockLocalDataSource.getGroupMembers('g1')).thenReturn([]);

      final result = await repository.updateMemberRole('g1', 'user1', 'viewer');

      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.getGroupMembers('g1')).called(1);
    });

    test('removeMember refreshes members after success', () async {
      when(
        () => mockRemoteDataSource.removeMember('g1', 'user2'),
      ).thenAnswer((_) async {});
      when(
        () => mockRemoteDataSource.getGroupMembers('g1'),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveGroupMembers(any()),
      ).thenAnswer((_) async {});
      when(() => mockLocalDataSource.getGroupMembers('g1')).thenReturn([]);

      final result = await repository.removeMember('g1', 'user2');

      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.getGroupMembers('g1')).called(1);
    });
  });
}
