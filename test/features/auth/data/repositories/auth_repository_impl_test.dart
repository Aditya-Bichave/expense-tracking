import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockUser extends Mock implements User {}

class MockAuthResponse extends Mock implements AuthResponse {}

void main() {
  late AuthRepositoryImpl repository;
  late MockAuthRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  group('signInWithOtp', () {
    const tPhone = '+1234567890';

    test('should return Right(null) when successful', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signInWithOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async {});

      // Act
      final result = await repository.signInWithOtp(tPhone);

      // Assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.signInWithOtp(phone: tPhone)).called(1);
    });

    test('should return ServerFailure when call fails', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.signInWithOtp(phone: any(named: 'phone')),
      ).thenThrow(Exception('Error'));

      // Act
      final result = await repository.signInWithOtp(tPhone);

      // Assert
      expect(result.isLeft(), true);
      result.fold(
        (failure) => expect(failure, isA<ServerFailure>()),
        (_) => fail('Should have failed'),
      );
    });
  });

  group('verifyOtp', () {
    const tPhone = '+1234567890';
    const tToken = '123456';
    final tAuthResponse = MockAuthResponse();

    test('should return Right(AuthResponse) when successful', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.verifyOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => tAuthResponse);

      // Act
      final result = await repository.verifyOtp(phone: tPhone, token: tToken);

      // Assert
      expect(result, Right(tAuthResponse));
      verify(
        () => mockRemoteDataSource.verifyOtp(phone: tPhone, token: tToken),
      ).called(1);
    });

    test('should return ServerFailure when call fails', () async {
      // Arrange
      when(
        () => mockRemoteDataSource.verifyOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenThrow(Exception('Error'));

      // Act
      final result = await repository.verifyOtp(phone: tPhone, token: tToken);

      // Assert
      expect(result.isLeft(), true);
    });
  });

  group('signOut', () {
    test('should return Right(null) when successful', () async {
      // Arrange
      when(() => mockRemoteDataSource.signOut()).thenAnswer((_) async {});

      // Act
      final result = await repository.signOut();

      // Assert
      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.signOut()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return Right(User) when user exists', () {
      // Arrange
      final mockUser = MockUser();
      when(() => mockRemoteDataSource.getCurrentUser()).thenReturn(mockUser);

      // Act
      final result = repository.getCurrentUser();

      // Assert
      expect(result, Right(mockUser));
    });

    test('should return Right(null) when user does not exist', () {
      // Arrange
      when(() => mockRemoteDataSource.getCurrentUser()).thenReturn(null);

      // Act
      final result = repository.getCurrentUser();

      // Assert
      expect(result, const Right(null));
    });
  });
}
