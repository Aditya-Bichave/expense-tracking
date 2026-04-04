import 'package:expense_tracker/core/utils/logger.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;

  AuthRepositoryImpl(this._remoteDataSource);

  @override
  Future<Either<Failure, void>> signInWithOtp(String phone) async {
    try {
      await _remoteDataSource.signInWithOtp(phone: phone);
      return const Right(null);
    } catch (e, s) {
      log.severe('Authentication failed during OTP sign in: $e\n$s');
      return Left(ServerFailure('Authentication failed'));
    }
  }

  @override
  Future<Either<Failure, void>> signInWithMagicLink(String email) async {
    try {
      await _remoteDataSource.signInWithMagicLink(email: email);
      return const Right(null);
    } catch (e, s) {
      log.severe('Authentication failed during Magic Link sign in: $e\n$s');
      return Left(ServerFailure('Authentication failed'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> signInAnonymously() async {
    try {
      final response = await _remoteDataSource.signInAnonymously();
      return Right(response);
    } catch (e, s) {
      log.severe('Authentication failed during anonymous sign in: $e\n$s');
      return Left(ServerFailure('Authentication failed'));
    }
  }

  @override
  Future<Either<Failure, AuthResponse>> verifyOtp({
    required String phone,
    required String token,
  }) async {
    try {
      final response = await _remoteDataSource.verifyOtp(
        phone: phone,
        token: token,
      );
      return Right(response);
    } catch (e, s) {
      log.severe('Authentication failed during OTP verification: $e\n$s');
      return Left(ServerFailure('Authentication failed'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _remoteDataSource.signOut();

      try {
        // Use DataManagementRepository to clear all Hive boxes safely
        final dataRepo = sl<DataManagementRepository>();
        await dataRepo.clearAllData();
      } catch (_) {
        // Ignore errors during local data clearing to ensure logout proceeds
      }

      try {
        final storage = sl<SecureStorageService>();
        await storage.clearAll();
      } catch (e, s) {
        log.severe('Silent failure: $e\n$s');
      }

      return const Right(null);
    } catch (e, s) {
      log.severe('Authentication failed during sign out: $e\n$s');
      return Left(ServerFailure('Authentication failed'));
    }
  }

  @override
  Either<Failure, User?> getCurrentUser() {
    try {
      return Right(_remoteDataSource.getCurrentUser());
    } catch (e, s) {
      log.severe('Failed to get current user: $e\n$s');
      return Left(CacheFailure('Authentication failed'));
    }
  }

  @override
  Stream<AuthState> get authStateChanges => _remoteDataSource.authStateChanges;
}
