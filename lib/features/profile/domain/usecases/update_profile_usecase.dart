import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';

class UpdateProfileUseCase implements UseCase<void, UserProfile> {
  final ProfileRepository repository;

  UpdateProfileUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UserProfile profile) async {
    return await repository.updateProfile(profile);
  }
}
