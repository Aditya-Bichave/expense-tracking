import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class DeleteGroup {
  final GroupsRepository repository;

  DeleteGroup(this.repository);

  Future<Either<Failure, void>> call(String groupId) {
    return repository.deleteGroup(groupId);
  }
}
