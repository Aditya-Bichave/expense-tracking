import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class UpdateGroup {
  final GroupsRepository repository;

  UpdateGroup(this.repository);

  Future<Either<Failure, GroupEntity>> call(GroupEntity group) {
    return repository.updateGroup(group);
  }
}
