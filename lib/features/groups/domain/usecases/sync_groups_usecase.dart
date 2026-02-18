import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/groups/domain/repositories/groups_repository.dart';

class SyncGroupsUseCase implements UseCase<void, NoParams> {
  final GroupsRepository repository;

  SyncGroupsUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) {
    return repository.syncGroups();
  }
}
