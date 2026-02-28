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
import 'dart:async'; // For unawaited

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
        unawaited(_syncService.processOutbox());
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
      if (e is Failure) return Left(e);
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
      if (e is Failure) return Left(e);
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncGroups() async {
    return refreshGroupsFromServer();
  }

  @override
  Future<Either<Failure, void>> refreshGroupsFromServer() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return const Right(null);
      }

      final remoteGroups = await _remoteDataSource.getGroups();
      await _localDataSource.saveGroups(remoteGroups);

      // Cleanup stale groups
      // ⚡ Bolt Optimization: Batch deletion
      // Reduces N+1 local db delete calls to a single batch delete, significantly improving performance for sync.
      final remoteGroupIds = remoteGroups.map((g) => g.id).toSet();
      final localGroups = _localDataSource.getGroups();
      final staleGroupIds = localGroups
          .where((lg) => !remoteGroupIds.contains(lg.id))
          .map((lg) => lg.id)
          .toList();
      if (staleGroupIds.isNotEmpty) {
        await _localDataSource.deleteGroups(staleGroupIds);
      }

      // Fetch members for each group in parallel
      await Future.wait(
        remoteGroups.map((group) async {
          try {
            final remoteMembers = await _remoteDataSource.getGroupMembers(
              group.id,
            );
            await _localDataSource.saveGroupMembers(remoteMembers);

            // Cleanup stale members
            // ⚡ Bolt Optimization: Batch deletion
            // Avoids O(N) single deletions, grouping them in a single fast I/O call.
            final remoteMemberIds = remoteMembers.map((m) => m.id).toSet();
            final localMembers = _localDataSource.getGroupMembers(group.id);
            final staleMemberIds = localMembers
                .where((lm) => !remoteMemberIds.contains(lm.id))
                .map((lm) => lm.id)
                .toList();
            if (staleMemberIds.isNotEmpty) {
              await _localDataSource.deleteMembers(staleMemberIds);
            }
          } catch (e) {
            // Log error or ignore partial failure
          }
        }),
      );

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
      // Refresh members for this group to keep UI in sync
      final members = await _remoteDataSource.getGroupMembers(groupId);
      await _localDataSource.saveGroupMembers(members);
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
      // Refresh members for this group to keep UI in sync
      // Since removeMember removes from DB, getGroupMembers won't return it.
      // We need to cleanup local cache.
      final members = await _remoteDataSource.getGroupMembers(groupId);
      await _localDataSource.saveGroupMembers(members);

      // Cleanup stale members
      // ⚡ Bolt Optimization: Replace loop-based deletes with single batch `deleteAll`
      // Greatly improves cleanup performance.
      final remoteMemberIds = members.map((m) => m.id).toSet();
      final localMembers = _localDataSource.getGroupMembers(groupId);
      final staleMemberIds = localMembers
          .where((lm) => !remoteMemberIds.contains(lm.id))
          .map((lm) => lm.id)
          .toList();
      if (staleMemberIds.isNotEmpty) {
        await _localDataSource.deleteMembers(staleMemberIds);
      }

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
