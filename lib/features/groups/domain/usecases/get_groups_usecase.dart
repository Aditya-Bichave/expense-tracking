import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class GetGroupsUseCase implements UseCase<List<GroupEntity>, NoParams> {
  final GroupsRepository repository;

  GetGroupsUseCase(this.repository);

  @override
  Future<Either<Failure, List<GroupEntity>>> call(NoParams params) {
    return repository.getGroups();
  }
}
