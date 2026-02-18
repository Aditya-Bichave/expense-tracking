import 'dart:convert';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/auth/auth_session_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/events/data_change_event.dart';
import 'package:expense_tracker/core/sync/models/entity_type.dart';
import 'package:expense_tracker/core/sync/models/op_type.dart';
import 'package:expense_tracker/core/sync/models/outbox_item.dart';
import 'package:expense_tracker/core/sync/repositories/outbox_repository.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/groups_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_members_local_data_source.dart';
import 'package:expense_tracker/features/groups/data/datasources/group_members_remote_data_source.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';
import 'package:uuid/uuid.dart';

class GroupsRepositoryImpl implements GroupsRepository {
  final GroupsLocalDataSource _localDataSource;
  final GroupsRemoteDataSource _remoteDataSource;
  final GroupMembersLocalDataSource _membersLocalDataSource;
  final GroupMembersRemoteDataSource _membersRemoteDataSource;
  final OutboxRepository _outboxRepository;
  final AuthSessionService _authService;
  final Uuid _uuid;

  GroupsRepositoryImpl({
    required GroupsLocalDataSource localDataSource,
    required GroupsRemoteDataSource remoteDataSource,
    required GroupMembersLocalDataSource membersLocalDataSource,
    required GroupMembersRemoteDataSource membersRemoteDataSource,
    required OutboxRepository outboxRepository,
    required AuthSessionService authService,
    required Uuid uuid,
  }) : _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _membersLocalDataSource = membersLocalDataSource,
       _membersRemoteDataSource = membersRemoteDataSource,
       _outboxRepository = outboxRepository,
       _authService = authService,
       _uuid = uuid;

  @override
  Future<Either<Failure, List<GroupEntity>>> getGroups() async {
    try {
      final localGroups = _localDataSource.getGroups();
      return Right(localGroups.map((e) => e.toEntity()).toList());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> createGroup(String name) async {
    try {
      final userId = _authService.currentUser?.id;
      if (userId == null) {
        return const Left(AuthenticationFailure('User not logged in'));
      }

      final id = _uuid.v4();
      final now = DateTime.now();

      final group = GroupModel(
        id: id,
        name: name,
        createdBy: userId,
        createdAt: now,
        updatedAt: now,
      );

      // 1. Save to local
      await _localDataSource.addGroup(group);

      // 2. Add to outbox
      final outboxItem = OutboxItem(
        id: _uuid.v4(),
        entityType: EntityType.group,
        opType: OpType.create,
        payloadJson: jsonEncode(group.toJson()),
        createdAt: now,
        entityId: id,
      );
      await _outboxRepository.add(outboxItem);

      // 3. Notify UI
      publishDataChangedEvent(
        type: DataChangeType.initialLoad,
        reason: DataChangeReason.localChange,
      );

      return Right(group.toEntity());
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, GroupEntity>> getGroup(String id) async {
    try {
      final localGroup = _localDataSource.getGroup(id);
      if (localGroup != null) {
        return Right(localGroup.toEntity());
      }
      return const Left(NotFoundFailure('Group not found locally'));
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> syncGroups() async {
    try {
      final remoteGroups = await _remoteDataSource.getGroups();
      await _localDataSource.cacheGroups(remoteGroups);
      // Also sync members for each group? Or lazily?
      // For now, assume lazy or handled elsewhere.
      publishDataChangedEvent(
        type: DataChangeType.initialLoad,
        reason: DataChangeReason.remoteSync,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<GroupMemberEntity>>> getGroupMembers(
    String groupId,
  ) async {
    try {
      // Return local first
      final local = _membersLocalDataSource.getMembersForGroup(groupId);
      if (local.isNotEmpty) {
        return Right(local.map((e) => e.toEntity()).toList());
      }
      // If empty, maybe try remote? Or rely on sync.
      // Let's try remote as fallback if local empty (and connected?)
      // But adhering to "read local cache first", we return empty list if not synced.
      return Right([]);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
