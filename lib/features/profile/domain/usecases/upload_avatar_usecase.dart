import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'dart:io';

class UploadAvatarUseCase implements UseCase<String, File> {
  final ProfileRepository repository;

  UploadAvatarUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(File file) async {
    return await repository.uploadAvatar(file);
  }
}
