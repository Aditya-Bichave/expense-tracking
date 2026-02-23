import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<Either<Failure, void>> signInWithOtp(String phone);
  Future<Either<Failure, void>> signInWithMagicLink(String email);
  Future<Either<Failure, AuthResponse>> signInAnonymously();
  Future<Either<Failure, AuthResponse>> verifyOtp({
    required String phone,
    required String token,
  });
  Future<Either<Failure, void>> signOut();
  Either<Failure, User?> getCurrentUser();
  Stream<AuthState> get authStateChanges;
}
