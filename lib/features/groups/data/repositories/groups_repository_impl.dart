import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/sync/models/sync_mutation_model.dart';
import 'package:expense_tracker/core/sync/outbox_repository.dart';
import 'package:expense_tracker/core/sync/sync_service.dart';
import 'package:expense_tracker/core/utils/logger.dart';
import 'package:expense_tracker/features/group_expenses/data/datasources/group_expenses_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
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
  final GroupExpensesLocalDataSource _groupExpensesLocalDataSource;

  GroupsRepositoryImpl({
    required GroupsLocalDataSource localDataSource,
    required GroupsRemoteDataSource remoteDataSource,
    required OutboxRepository outboxRepository,
    required SyncService syncService,
    required Connectivity connectivity,
    required GroupExpensesLocalDataSource groupExpensesLocalDataSource,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _outboxRepository = outboxRepository,
       _syncService = syncService,
       _connectivity = connectivity,
       _groupExpensesLocalDataSource = groupExpensesLocalDataSource;

  @override
  Future<Either<Failure, GroupEntity>> createGroup(GroupEntity group) async {
    try {
      final model = GroupModel.fromEntity(group);
      await _localDataSource.saveGroup(model);
      await _localDataSource.saveGroupMembers([_buildLocalAdminMember(group)]);
      await _outboxRepository.add(
        SyncMutationModel(
          id: group.id,
          table: 'groups',
          operation: OpType.create,
          payload: model.toJson(),
          createdAt: DateTime.now(),
        ),
      );
      await _syncIfConnected();

      return Right(group);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> updateGroup(GroupEntity group) async {
    try {
      final model = GroupModel.fromEntity(group);
      await _localDataSource.saveGroup(model);
      await _outboxRepository.add(
        SyncMutationModel(
          id: group.id,
          table: 'groups',
          operation: OpType.update,
          payload: model.toUpdateJson(),
          createdAt: DateTime.now(),
        ),
      );
      await _syncIfConnected();

      return Right(group);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteGroup(String groupId) async {
    try {
      await _cleanupGroupLocally(groupId);
      await _outboxRepository.add(
        SyncMutationModel(
          id: groupId,
          table: 'groups',
          operation: OpType.delete,
          payload: {'id': groupId},
          createdAt: DateTime.now(),
        ),
      );
      await _syncIfConnected();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> leaveGroup(
    String groupId,
    String userId,
  ) async {
    try {
      await _cleanupGroupLocally(groupId);
      await _outboxRepository.add(
        SyncMutationModel(
          id: '$groupId:$userId',
          table: 'group_members',
          operation: OpType.delete,
          payload: {'group_id': groupId, 'user_id': userId},
          createdAt: DateTime.now(),
        ),
      );
      await _syncIfConnected();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupEntity>>> getGroups() async {
    try {
      return Right(_mapAndSortGroups(_localDataSource.getGroups()));
    } catch (e, s) {
      log.severe("Exception in repository: $e\n$s");
      if (e is Failure) {
        return Left(e);
      }
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Stream<Either<Failure, List<GroupEntity>>> watchGroups() {
    return _localDataSource
        .watchGroups()
        .map<Either<Failure, List<GroupEntity>>>(
          (models) => Right(_mapAndSortGroups(models)),
        )
        .onErrorReturnWith(
          (error, stackTrace) => Left(CacheFailure(error.toString())),
        );
  }

  @override
  Future<Either<Failure, List<GroupMember>>> getGroupMembers(
    String groupId,
  ) async {
    try {
      final models = _localDataSource.getGroupMembers(groupId);
      return Right(models.map((model) => model.toEntity()).toList());
    } catch (e, s) {
      log.severe("Exception in repository: $e\n$s");
      if (e is Failure) {
        return Left(e);
      }
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

      final remoteGroupIds = remoteGroups.map((group) => group.id).toSet();
      final staleGroupIds = _localDataSource
          .getGroups()
          .where((group) => !remoteGroupIds.contains(group.id))
          .map((group) => group.id)
          .toList();
      if (staleGroupIds.isNotEmpty) {
        await _localDataSource.deleteGroups(staleGroupIds);
        await Future.wait(
          staleGroupIds.map(_localDataSource.deleteGroupMembers),
        );
        await Future.wait(
          staleGroupIds.map(
            _groupExpensesLocalDataSource.deleteExpensesForGroup,
          ),
        );
      }

      await Future.wait(remoteGroups.map(_syncRemoteMembersForGroup));

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
      await _syncRemoteMembersForGroupById(groupId);
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
      await _syncRemoteMembersForGroupById(groupId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  List<GroupEntity> _mapAndSortGroups(List<GroupModel> models) {
    final groups = models.map((model) => model.toEntity()).toList();
    groups.sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return groups;
  }

  GroupMemberModel _buildLocalAdminMember(GroupEntity group) {
    final now = DateTime.now();
    return GroupMemberModel(
      id: '${group.id}:${group.createdBy}:local-admin',
      groupId: group.id,
      userId: group.createdBy,
      roleValue: 'admin',
      joinedAt: now,
      updatedAt: now,
    );
  }

  Future<void> _cleanupGroupLocally(String groupId) async {
    await _localDataSource.deleteGroup(groupId);
    await _localDataSource.deleteGroupMembers(groupId);
    await _groupExpensesLocalDataSource.deleteExpensesForGroup(groupId);
  }

  Future<void> _syncRemoteMembersForGroup(GroupModel group) {
    return _syncRemoteMembersForGroupById(group.id);
  }

  Future<void> _syncRemoteMembersForGroupById(String groupId) async {
    try {
      final remoteMembers = await _remoteDataSource.getGroupMembers(groupId);
      await _localDataSource.saveGroupMembers(remoteMembers);

      final remoteMemberIds = remoteMembers.map((member) => member.id).toSet();
      final staleMemberIds = _localDataSource
          .getGroupMembers(groupId)
          .where((member) => !remoteMemberIds.contains(member.id))
          .map((member) => member.id)
          .toList();
      if (staleMemberIds.isNotEmpty) {
        await _localDataSource.deleteMembers(staleMemberIds);
      }
    } catch (error, stackTrace) {
      log.warning(
        'Failed to refresh members for group $groupId: $error\n$stackTrace',
      );
    }
  }

  Future<void> _syncIfConnected() async {
    final connectivityResult = await _connectivity.checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.mobile) ||
        connectivityResult.contains(ConnectivityResult.wifi)) {
      unawaited(
        _syncService.processOutbox().catchError((error, stackTrace) {
          log.severe(
            'Failed to process outbox in background: $error\n$stackTrace',
          );
        }),
      );
    }
  }
}
