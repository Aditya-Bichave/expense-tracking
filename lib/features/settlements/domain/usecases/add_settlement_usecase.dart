import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/settlements/domain/entities/settlement_entity.dart';
import 'package:expense_tracker/features/settlements/domain/repositories/settlements_repository.dart';

class AddSettlementUseCase implements UseCase<SettlementEntity, SettlementEntity> {
  final SettlementsRepository repository;

  AddSettlementUseCase(this.repository);

  @override
  Future<Either<Failure, SettlementEntity>> call(SettlementEntity params) {
    return repository.addSettlement(params);
  }
}
