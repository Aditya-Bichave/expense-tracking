import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'dart:io';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource _remoteDataSource;
  final ProfileLocalDataSource _localDataSource;
  final AuthRepository _authRepository;

  ProfileRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._authRepository,
  );

  @override
  Future<Either<Failure, UserProfile>> getProfile({
    bool forceRefresh = false,
  }) async {
    try {
      if (!forceRefresh) {
        final localProfile = await _localDataSource.getLastProfile();
        if (localProfile != null) {
          return Right(localProfile);
        }
      }

      final userResult = _authRepository.getCurrentUser();
      return await userResult.fold((failure) => Left(failure), (user) async {
        if (user == null) {
          return const Left(ServerFailure("No user logged in"));
        }
        final remoteProfile = await _remoteDataSource.getProfile(user.id);
        await _localDataSource.cacheProfile(remoteProfile);
        return Right(remoteProfile);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateProfile(UserProfile profile) async {
    try {
      final model = ProfileModel.fromEntity(profile);
      await _remoteDataSource.updateProfile(model);
      await _localDataSource.cacheProfile(model);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, String>> uploadAvatar(File file) async {
    try {
      final userResult = _authRepository.getCurrentUser();
      return await userResult.fold((failure) => Left(failure), (user) async {
        if (user == null) {
          return const Left(ServerFailure("No user logged in"));
        }
        final url = await _remoteDataSource.uploadAvatar(user.id, file);
        return Right(url);
      });
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearProfileCache() async {
    try {
      await _localDataSource.clearProfile();
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
