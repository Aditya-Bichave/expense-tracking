import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/invites/domain/repositories/invites_repository.dart';

class AcceptInviteParams {
  final String token;
  AcceptInviteParams(this.token);
}

class AcceptInviteUseCase implements UseCase<void, AcceptInviteParams> {
  final InvitesRepository repository;

  AcceptInviteUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AcceptInviteParams params) {
    return repository.acceptInvite(params.token);
  }
}
