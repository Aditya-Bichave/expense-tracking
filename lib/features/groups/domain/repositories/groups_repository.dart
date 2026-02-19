import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';

abstract class GroupsRepository {
  Future<Either<Failure, GroupEntity>> createGroup(GroupEntity group);
  Future<Either<Failure, List<GroupEntity>>> getGroups();
  Future<Either<Failure, List<GroupMember>>> getGroupMembers(String groupId);
  Future<Either<Failure, void>> syncGroups();
  Future<Either<Failure, String>> createInvite(String groupId);
  Future<Either<Failure, void>> acceptInvite(String token);
}
