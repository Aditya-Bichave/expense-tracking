import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';

class GetProfileUseCase {
  final ProfileRepository repository;

  GetProfileUseCase(this.repository);

  Future<Either<Failure, UserProfile>> call({bool forceRefresh = false}) async {
    return await repository.getProfile(forceRefresh: forceRefresh);
  }
}
