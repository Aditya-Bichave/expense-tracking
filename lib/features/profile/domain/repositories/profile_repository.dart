import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'dart:io';

abstract class ProfileRepository {
  Future<Either<Failure, UserProfile>> getProfile({bool forceRefresh = false});
  Future<Either<Failure, void>> updateProfile(UserProfile profile);
  Future<Either<Failure, String>> uploadAvatar(File file);
  Future<Either<Failure, void>> clearProfileCache();
}
