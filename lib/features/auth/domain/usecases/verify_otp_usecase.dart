import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyOtpUseCase {
  final AuthRepository _repository;

  VerifyOtpUseCase(this._repository);

  Future<Either<Failure, AuthResponse>> call({
    required String phone,
    required String token,
  }) async {
    return await _repository.verifyOtp(phone: phone, token: token);
  }
}
