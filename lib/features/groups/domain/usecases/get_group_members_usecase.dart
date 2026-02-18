import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class GetGroupMembersParams {
  final String groupId;
  GetGroupMembersParams(this.groupId);
}

class GetGroupMembersUseCase implements UseCase<List<GroupMemberEntity>, GetGroupMembersParams> {
  final GroupsRepository repository;

  GetGroupMembersUseCase(this.repository);

  @override
  Future<Either<Failure, List<GroupMemberEntity>>> call(GetGroupMembersParams params) {
    return repository.getGroupMembers(params.groupId);
  }
}
