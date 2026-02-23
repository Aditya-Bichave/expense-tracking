import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/data/repositories/groups_repository_impl.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupsLocalDataSource extends Mock implements GroupsLocalDataSource {}

class MockGroupsRemoteDataSource extends Mock
    implements GroupsRemoteDataSource {}

class MockOutboxRepository extends Mock implements OutboxRepository {}

class MockSyncService extends Mock implements SyncService {}

class MockConnectivity extends Mock implements Connectivity {}

class FakeGroupModel extends Fake implements GroupModel {}

class FakeOutboxItem extends Fake implements OutboxItem {}

void main() {
  late GroupsRepositoryImpl repository;
  late MockGroupsLocalDataSource mockLocalDataSource;
  late MockGroupsRemoteDataSource mockRemoteDataSource;
  late MockOutboxRepository mockOutboxRepository;
  late MockSyncService mockSyncService;
  late MockConnectivity mockConnectivity;

  setUpAll(() {
    registerFallbackValue(FakeGroupModel());
    registerFallbackValue(FakeOutboxItem());
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
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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
  });

  group('syncGroups', () {
    final tGroupModel = GroupModel(
      id: '1',
      name: 'Test Group',
      createdBy: 'user1',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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

      // Act
      final result = await repository.syncGroups();

      // Assert
      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.getGroups()).called(1);
      verify(() => mockLocalDataSource.saveGroups([tGroupModel])).called(1);
    });

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
    test('should call remoteDataSource.updateMemberRole', () async {
      when(
        () => mockRemoteDataSource.updateMemberRole(any(), any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.updateMemberRole('1', 'u1', 'admin');

      expect(result.isRight(), true);
      verify(
        () => mockRemoteDataSource.updateMemberRole('1', 'u1', 'admin'),
      ).called(1);
    });

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
    test('should call remoteDataSource.removeMember', () async {
      when(
        () => mockRemoteDataSource.removeMember(any(), any()),
      ).thenAnswer((_) async {});

      final result = await repository.removeMember('1', 'u1');

      expect(result.isRight(), true);
      verify(() => mockRemoteDataSource.removeMember('1', 'u1')).called(1);
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
