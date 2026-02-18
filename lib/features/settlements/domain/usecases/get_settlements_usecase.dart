import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settlements/domain/entities/settlement_entity.dart';
import 'package:expense_tracker/features/settlements/domain/repositories/settlements_repository.dart';

class GetSettlementsParams {
  final String groupId;
  GetSettlementsParams(this.groupId);
}

class GetSettlementsUseCase
    implements UseCase<List<SettlementEntity>, GetSettlementsParams> {
  final SettlementsRepository repository;

  GetSettlementsUseCase(this.repository);

  @override
  Future<Either<Failure, List<SettlementEntity>>> call(
    GetSettlementsParams params,
  ) {
    return repository.getSettlements(params.groupId);
  }
}
