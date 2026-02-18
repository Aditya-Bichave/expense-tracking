import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class GetGroupParams {
  final String id;
  GetGroupParams(this.id);
}

class GetGroupUseCase implements UseCase<GroupEntity, GetGroupParams> {
  final GroupsRepository repository;

  GetGroupUseCase(this.repository);

  @override
  Future<Either<Failure, GroupEntity>> call(GetGroupParams params) {
    return repository.getGroup(params.id);
  }
}
