import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class CreateGroupParams {
  final String name;
  CreateGroupParams({required this.name});
}

class CreateGroupUseCase implements UseCase<GroupEntity, CreateGroupParams> {
  final GroupsRepository repository;

  CreateGroupUseCase(this.repository);

  @override
  Future<Either<Failure, GroupEntity>> call(CreateGroupParams params) {
    return repository.createGroup(params.name);
  }
}
