import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class JoinGroup {
  final GroupsRepository repository;

  JoinGroup(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call(String token) async {
    return await repository.acceptInvite(token);
  }
}
