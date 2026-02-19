import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';

class LoginWithOtpUseCase {
  final AuthRepository _repository;

  LoginWithOtpUseCase(this._repository);

  Future<Either<Failure, void>> call(String phone) async {
    return await _repository.signInWithOtp(phone);
  }
}
