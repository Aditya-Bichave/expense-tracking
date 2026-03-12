import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class LeaveGroup {
  final GroupsRepository repository;

  LeaveGroup(this.repository);

  Future<Either<Failure, void>> call(String groupId, String userId) {
    return repository.leaveGroup(groupId, userId);
  }
}
