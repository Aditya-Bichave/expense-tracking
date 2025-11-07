import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability.dart';
import 'package:expense_tracker/features/accounts/domain/repositories/liability_repository.dart';

class GetLiabilitiesUseCase implements UseCase<List<Liability>, NoParams> {
  final LiabilityRepository repository;

  GetLiabilitiesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Liability>>> call(NoParams params) async {
    return await repository.getLiabilities();
  }
}
