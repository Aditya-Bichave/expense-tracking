import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:rxdart/rxdart.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsLocalDataSource _localDataSource;
  final GroupsRemoteDataSource _remoteDataSource;
  final OutboxRepository _outboxRepository;
  final SyncService _syncService;
  final Connectivity _connectivity;

  GroupsRepositoryImpl({
    required GroupsLocalDataSource localDataSource,
    required GroupsRemoteDataSource remoteDataSource,
    required OutboxRepository outboxRepository,
    required SyncService syncService,
    required Connectivity connectivity,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _outboxRepository = outboxRepository,
       _syncService = syncService,
       _connectivity = connectivity;

  @override
  Future<Either<Failure, GroupEntity>> createGroup(GroupEntity group) async {
    try {
      final model = GroupModel.fromEntity(group);
      await _localDataSource.saveGroup(model);

      final outboxItem = SyncMutationModel(
        id: group.id,
        table: 'groups',
        operation: OpType.create,
        payload: model.toJson(),
        createdAt: DateTime.now(),
      );
      await _outboxRepository.add(outboxItem);

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.mobile) ||
          connectivityResult.contains(ConnectivityResult.wifi)) {
        _syncService.processOutbox();
      }

      return Right(group);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getGroups() async {
    try {
      final models = _localDataSource.getGroups();
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<GroupEntity>>> watchGroups() {
    return _localDataSource
        .watchGroups()
        .map<Either<Failure, List<GroupEntity>>>((models) {
          return Right(models.map((e) => e.toEntity()).toList());
        })
        .onErrorReturnWith((error, stackTrace) {
          return Left<Failure, List<GroupEntity>>(
            CacheFailure(error.toString()),
          );
        });
  }

  @override
  Future<Either<Failure, List<GroupMember>>> getGroupMembers(
    String groupId,
  ) async {
    try {
      final models = _localDataSource.getGroupMembers(groupId);
      return Right(models.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncGroups() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return const Right(null);
      }

      final remoteGroups = await _remoteDataSource.getGroups();
      await _localDataSource.saveGroups(remoteGroups);

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> createInvite(
    String groupId, {
    String role = 'member',
    int expiryDays = 7,
    int maxUses = 0,
  }) async {
    try {
      final url = await _remoteDataSource.createInvite(
        groupId,
        role: role,
        expiryDays: expiryDays,
        maxUses: maxUses,
      );
      return Right(url);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> acceptInvite(
    String token,
  ) async {
    try {
      final data = await _remoteDataSource.acceptInvite(token);
      return Right(data);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateMemberRole(
    String groupId,
    String userId,
    String role,
  ) async {
    try {
      await _remoteDataSource.updateMemberRole(groupId, userId, role);
      // Sync local members if possible or just rely on realtime
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeMember(
    String groupId,
    String userId,
  ) async {
    try {
      await _remoteDataSource.removeMember(groupId, userId);
      // Sync local members if possible or just rely on realtime
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
