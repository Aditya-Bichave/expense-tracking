import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class WatchGroups {
  final GroupsRepository repository;

  WatchGroups(this.repository);

  Stream<Either<Failure, List<GroupEntity>>> call() {
    return repository.watchGroups();
  }
}
