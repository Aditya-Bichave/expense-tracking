import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/invites/domain/entities/invite_entity.dart';

abstract class InvitesRepository {
  Future<Either<Failure, InviteEntity>> createInvite(String groupId);
  Future<Either<Failure, void>> acceptInvite(String token);
}
