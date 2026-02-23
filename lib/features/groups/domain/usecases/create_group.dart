import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class CreateGroup {
  final GroupsRepository repository;

  CreateGroup(this.repository);

  Future<Either<Failure, GroupEntity>> call(GroupEntity group) async {
    return await repository.createGroup(group);
  }
}
