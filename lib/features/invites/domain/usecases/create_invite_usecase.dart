import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/invites/domain/entities/invite_entity.dart';
import 'package:expense_tracker/features/invites/domain/repositories/invites_repository.dart';

class CreateInviteParams {
  final String groupId;
  CreateInviteParams(this.groupId);
}

class CreateInviteUseCase implements UseCase<InviteEntity, CreateInviteParams> {
  final InvitesRepository repository;

  CreateInviteUseCase(this.repository);

  @override
  Future<Either<Failure, InviteEntity>> call(CreateInviteParams params) {
    return repository.createInvite(params.groupId);
  }
}
