import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
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

class FakeSyncMutationModel extends Fake implements SyncMutationModel {}

class FakeGroupModel extends Fake implements GroupModel {}

void main() {
  late GroupsRepositoryImpl repository;
  late MockGroupsLocalDataSource mockLocalDataSource;
  late MockGroupsRemoteDataSource mockRemoteDataSource;
  late MockOutboxRepository mockOutboxRepository;
  late MockSyncService mockSyncService;
  late MockConnectivity mockConnectivity;

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
    repository = GroupsRepositoryImpl(
      localDataSource: mockLocalDataSource,
      remoteDataSource: mockRemoteDataSource,
      outboxRepository: mockOutboxRepository,
      syncService: mockSyncService,
      connectivity: mockConnectivity,
    );
  });

  group('createGroup', () {
    final tGroup = GroupEntity(
      id: '1',
      name: 'Test Group',
      type: GroupType.trip,
      currency: 'USD',
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: false,
    );

    test(
      'should save locally, add to outbox, and trigger sync if connected',
      () async {
        // Arrange
        when(
          () => mockLocalDataSource.saveGroup(any()),
        ).thenAnswer((_) async {});
        when(() => mockOutboxRepository.add(any())).thenAnswer((_) async {});
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(() => mockSyncService.processOutbox()).thenAnswer((_) async {});

        // Act
        final result = await repository.createGroup(tGroup);

        // Assert
        expect(result.isRight(), true);
        verify(() => mockLocalDataSource.saveGroup(any())).called(1);
        verify(() => mockOutboxRepository.add(any())).called(1);
        verify(() => mockSyncService.processOutbox()).called(1);
      },
    );

    test('should return CacheFailure if local save fails', () async {
      // Arrange
      when(
        () => mockLocalDataSource.saveGroup(any()),
      ).thenThrow(Exception('Cache Error'));

      // Act
      final result = await repository.createGroup(tGroup);

      // Assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<CacheFailure>());
    });
  });

  group('getGroups', () {
    final tGroupModel = GroupModel(
      id: '1',
      name: 'Test Group',
      typeValue: 'trip',
      currency: 'USD',
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: false,
    );

    test('should return groups from local source', () async {
      // Arrange
      when(() => mockLocalDataSource.getGroups()).thenReturn([tGroupModel]);

      // Act
      final result = await repository.getGroups();

      // Assert
      expect(result.isRight(), true);
      result.fold(
        (_) => fail('Should be right'),
        (groups) => expect(groups.length, 1),
      );
    });

    test('should return CacheFailure on exception', () async {
      // Arrange
      when(() => mockLocalDataSource.getGroups()).thenThrow(Exception('Error'));

      // Act
      final result = await repository.getGroups();

      // Assert
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<CacheFailure>());
    });
  });

  group('watchGroups', () {
    final tGroupModel = GroupModel(
      id: '1',
      name: 'Test Group',
      typeValue: 'trip',
      currency: 'USD',
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: false,
    );

    test('should return a stream of Right(List<GroupEntity>)', () {
      when(
        () => mockLocalDataSource.watchGroups(),
      ).thenAnswer((_) => Stream.value([tGroupModel]));
      final stream = repository.watchGroups();
      expect(stream, emits(isA<Right<Failure, List<GroupEntity>>>()));
    });

    test('should return a stream with Left(CacheFailure) on error', () {
      when(
        () => mockLocalDataSource.watchGroups(),
      ).thenAnswer((_) => Stream.error(Exception('Error')));
      final stream = repository.watchGroups();
      expect(stream, emits(isA<Left<Failure, List<GroupEntity>>>()));
    });
  });

  group('getGroupMembers', () {
    final tModel = GroupMemberModel(
      id: 'm1',
      groupId: 'g1',
      userId: 'u1',
      roleValue: 'admin',
      joinedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    test('should return members from local source', () async {
      when(
        () => mockLocalDataSource.getGroupMembers('g1'),
      ).thenReturn([tModel]);
      final result = await repository.getGroupMembers('g1');
      expect(result.isRight(), true);
      result.fold(
        (l) => fail('Should be right'),
        (members) => expect(members.length, 1),
      );
    });

    test('should return CacheFailure on exception', () async {
      when(
        () => mockLocalDataSource.getGroupMembers('g1'),
      ).thenThrow(Exception('Error'));
      final result = await repository.getGroupMembers('g1');
      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<CacheFailure>());
    });
  });

  group('syncGroups', () {
    final tGroupModel = GroupModel(
      id: '1',
      name: 'Test Group',
      typeValue: 'trip',
      currency: 'USD',
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isArchived: false,
    );

    test('should fetch from remote and save to local when connected', () async {
      // Arrange
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);
      when(
        () => mockRemoteDataSource.getGroups(),
      ).thenAnswer((_) async => [tGroupModel]);
      when(
        () => mockLocalDataSource.saveGroups(any()),
      ).thenAnswer((_) async {});
      when(() => mockLocalDataSource.getGroups()).thenReturn([tGroupModel]);
      when(
        () => mockRemoteDataSource.getGroupMembers(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveGroupMembers(any()),
      ).thenAnswer((_) async {});
      when(() => mockLocalDataSource.getGroupMembers(any())).thenReturn([]);

      // Act
      final result = await repository.syncGroups();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.getGroups()).called(1);
      verify(() => mockLocalDataSource.saveGroups([tGroupModel])).called(1);
      verify(() => mockRemoteDataSource.getGroupMembers('1')).called(1);
    });

    test(
      'should return ServerFailure on exception during remote fetch',
      () async {
        when(
          () => mockConnectivity.checkConnectivity(),
        ).thenAnswer((_) async => [ConnectivityResult.wifi]);
        when(
          () => mockRemoteDataSource.getGroups(),
        ).thenThrow(Exception('Error'));

        final result = await repository.syncGroups();

        expect(result.isLeft(), true);
        expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
      },
    );

    test('should do nothing when offline', () async {
      // Arrange
      when(
        () => mockConnectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      // Act
      final result = await repository.syncGroups();

      // Assert
      expect(result.isRight(), true);
      verifyNever(() => mockRemoteDataSource.getGroups());
    });
  });

  group('createInvite', () {
    test('should call remoteDataSource.createInvite', () async {
      when(
        () => mockRemoteDataSource.createInvite(
          any(),
          role: any(named: 'role'),
          expiryDays: any(named: 'expiryDays'),
          maxUses: any(named: 'maxUses'),
        ),
      ).thenAnswer((_) async => 'https://link.com');

      final result = await repository.createInvite('1');

      expect(result.isRight(), true);
      result.fold((l) => null, (r) => expect(r, 'https://link.com'));
      verify(
        () => mockRemoteDataSource.createInvite(
          '1',
          role: 'member',
          expiryDays: 7,
          maxUses: 0,
        ),
      ).called(1);
    });

    test('should return ServerFailure on exception', () async {
      when(
        () => mockRemoteDataSource.createInvite(
          any(),
          role: any(named: 'role'),
          expiryDays: any(named: 'expiryDays'),
          maxUses: any(named: 'maxUses'),
        ),
      ).thenThrow(Exception('Error'));

      final result = await repository.createInvite('1');

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
    });
  });

  group('acceptInvite', () {
    test('should call remoteDataSource.acceptInvite', () async {
      when(
        () => mockRemoteDataSource.acceptInvite(any()),
      ).thenAnswer((_) async => {'group_id': '1'});

      final result = await repository.acceptInvite('token');

      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.acceptInvite('token')).called(1);
    });

    test('should return ServerFailure on exception', () async {
      when(
        () => mockRemoteDataSource.acceptInvite(any()),
      ).thenThrow(Exception('Error'));

      final result = await repository.acceptInvite('token');

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
    });
  });

  group('updateMemberRole', () {
    test(
      'should call remoteDataSource.updateMemberRole and refresh members',
      () async {
        when(
          () => mockRemoteDataSource.updateMemberRole(any(), any(), any()),
        ).thenAnswer((_) async {});
        when(
          () => mockRemoteDataSource.getGroupMembers(any()),
        ).thenAnswer((_) async => []);
        when(
          () => mockLocalDataSource.saveGroupMembers(any()),
        ).thenAnswer((_) async {});
        when(() => mockLocalDataSource.getGroupMembers(any())).thenReturn([]);

        final result = await repository.updateMemberRole('1', 'u1', 'admin');

        expect(result.isRight(), true);
        verify(
          () => mockRemoteDataSource.updateMemberRole('1', 'u1', 'admin'),
        ).called(1);
        verify(() => mockRemoteDataSource.getGroupMembers('1')).called(1);
      },
    );

    test('should return ServerFailure on exception', () async {
      when(
        () => mockRemoteDataSource.updateMemberRole(any(), any(), any()),
      ).thenThrow(Exception('Error'));

      final result = await repository.updateMemberRole('1', 'u1', 'admin');

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
    });
  });

  group('removeMember', () {
    test('should call remoteDataSource.removeMember and cleanup', () async {
      when(
        () => mockRemoteDataSource.removeMember(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => mockRemoteDataSource.getGroupMembers(any()),
      ).thenAnswer((_) async => []);
      when(
        () => mockLocalDataSource.saveGroupMembers(any()),
      ).thenAnswer((_) async {});
      when(() => mockLocalDataSource.getGroupMembers(any())).thenReturn([]);

      final result = await repository.removeMember('1', 'u1');

      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.removeMember('1', 'u1')).called(1);
      verify(() => mockRemoteDataSource.getGroupMembers('1')).called(1);
    });

    test('should return ServerFailure on exception', () async {
      when(
        () => mockRemoteDataSource.removeMember(any(), any()),
      ).thenThrow(Exception('Error'));

      final result = await repository.removeMember('1', 'u1');

      expect(result.isLeft(), true);
      expect(result.fold((l) => l, (r) => null), isA<ServerFailure>());
    });
  });
}
