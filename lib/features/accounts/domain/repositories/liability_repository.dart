import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability.dart';

abstract class LiabilityRepository {
  Future<Either<Failure, List<Liability>>> getLiabilities();
  Future<Either<Failure, Liability>> addLiability(Liability liability);
  Future<Either<Failure, Liability>> updateLiability(Liability liability);
  Future<Either<Failure, void>> deleteLiability(String id);
}
