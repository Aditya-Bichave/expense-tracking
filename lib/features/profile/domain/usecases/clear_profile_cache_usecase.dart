import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';

class ClearProfileCacheUseCase implements UseCase<void, NoParams> {
  final ProfileRepository repository;

  ClearProfileCacheUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.clearProfileCache();
  }
}
