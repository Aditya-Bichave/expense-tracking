import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/settlements/domain/entities/settlement_entity.dart';

abstract class SettlementsRepository {
  Future<Either<Failure, List<SettlementEntity>>> getSettlements(String groupId);
  Future<Either<Failure, SettlementEntity>> addSettlement(SettlementEntity settlement);
  Future<Either<Failure, void>> syncSettlements(String groupId);
}
