import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/invites/data/datasources/invites_remote_data_source.dart';
import 'package:expense_tracker/features/invites/domain/entities/invite_entity.dart';
import 'package:expense_tracker/features/invites/domain/repositories/invites_repository.dart';

class InvitesRepositoryImpl implements InvitesRepository {
  final InvitesRemoteDataSource _remoteDataSource;

  InvitesRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, InviteEntity>> createInvite(String groupId) async {
    try {
      final model = await _remoteDataSource.createInvite(groupId);
      return Right(model.toEntity());
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> acceptInvite(String token) async {
    try {
      await _remoteDataSource.acceptInvite(token);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
