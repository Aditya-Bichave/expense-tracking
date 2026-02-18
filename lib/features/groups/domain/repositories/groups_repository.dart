import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member_entity.dart';

abstract class GroupsRepository {
  Future<Either<Failure, List<GroupEntity>>> getGroups();
  Future<Either<Failure, GroupEntity>> createGroup(String name);
  Future<Either<Failure, GroupEntity>> getGroup(String id);
  Future<Either<Failure, void>> syncGroups();
  Future<Either<Failure, List<GroupMemberEntity>>> getGroupMembers(String groupId);
}
