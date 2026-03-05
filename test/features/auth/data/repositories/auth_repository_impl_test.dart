import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:expense_tracker/core/services/secure_storage_service.dart';
import 'package:expense_tracker/core/di/service_locator.dart';
import 'package:expense_tracker/features/settings/domain/repositories/data_management_repository.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class MockDataManagementRepository extends Mock
    implements DataManagementRepository {}

class MockSecureStorageService extends Mock implements SecureStorageService {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

void main() {
  late MockAuthRemoteDataSource mockRemoteDataSource;
  late MockDataManagementRepository mockDataManagement;
  late MockSecureStorageService mockSecureStorage;
  late AuthRepositoryImpl repository;

  setUp(() {
    mockRemoteDataSource = MockAuthRemoteDataSource();
    mockDataManagement = MockDataManagementRepository();
    mockSecureStorage = MockSecureStorageService();

    // Setup service locator mocks for the ones used directly via sl
    sl.allowReassignment = true;
    sl.registerFactory<DataManagementRepository>(() => mockDataManagement);
    sl.registerFactory<SecureStorageService>(() => mockSecureStorage);

    repository = AuthRepositoryImpl(mockRemoteDataSource);
  });

  tearDown(() async {
    await sl.reset();
  });

  group('signInWithOtp', () {
    const tPhone = '1234567890';

    test('should return Right(null) when call is successful', () async {
      when(
        () => mockRemoteDataSource.signInWithOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async => Future<void>.value());

      final result = await repository.signInWithOtp(tPhone);

      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.signInWithOtp(phone: tPhone)).called(1);
    });

    test(
      'should return Left(ServerFailure) when call throws exception',
      () async {
        when(
          () => mockRemoteDataSource.signInWithOtp(phone: any(named: 'phone')),
        ).thenThrow(Exception('error'));

        final result = await repository.signInWithOtp(tPhone);

        expect(result, isA<Left<Failure, void>>());
        result.fold((l) {
          expect(l, isA<ServerFailure>());
          expect(l.message, 'Exception: error');
        }, (r) => fail('Expected Left'));
      },
    );
  });

  group('signInWithMagicLink', () {
    const tEmail = 'test@example.com';

    test('should return Right(null) when call is successful', () async {
      when(
        () => mockRemoteDataSource.signInWithMagicLink(
          email: any(named: 'email'),
        ),
      ).thenAnswer((_) async => Future<void>.value());

      final result = await repository.signInWithMagicLink(tEmail);

      expect(result, const Right(null));
      verify(
        () => mockRemoteDataSource.signInWithMagicLink(email: tEmail),
      ).called(1);
    });

    test(
      'should return Left(ServerFailure) when call throws exception',
      () async {
        when(
          () => mockRemoteDataSource.signInWithMagicLink(
            email: any(named: 'email'),
          ),
        ).thenThrow(Exception('error'));

        final result = await repository.signInWithMagicLink(tEmail);

        expect(result, isA<Left<Failure, void>>());
        result.fold((l) {
          expect(l, isA<ServerFailure>());
          expect(l.message, 'Exception: error');
        }, (r) => fail('Expected Left'));
      },
    );
  });

  group('signInAnonymously', () {
    test('should return Right(AuthResponse) when call is successful', () async {
      final tResponse = MockAuthResponse();
      when(
        () => mockRemoteDataSource.signInAnonymously(),
      ).thenAnswer((_) async => tResponse);

      final result = await repository.signInAnonymously();

      expect(result, Right(tResponse));
      verify(() => mockRemoteDataSource.signInAnonymously()).called(1);
    });

    test(
      'should return Left(ServerFailure) when call throws exception',
      () async {
        when(
          () => mockRemoteDataSource.signInAnonymously(),
        ).thenThrow(Exception('error'));

        final result = await repository.signInAnonymously();

        expect(result, isA<Left<Failure, AuthResponse>>());
        result.fold((l) {
          expect(l, isA<ServerFailure>());
          expect(l.message, 'Exception: error');
        }, (r) => fail('Expected Left'));
      },
    );
  });

  group('verifyOtp', () {
    const tPhone = '1234567890';
    const tToken = '123456';

    test('should return Right(AuthResponse) when call is successful', () async {
      final tResponse = MockAuthResponse();
      when(
        () => mockRemoteDataSource.verifyOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => tResponse);

      final result = await repository.verifyOtp(phone: tPhone, token: tToken);

      expect(result, Right(tResponse));
      verify(
        () => mockRemoteDataSource.verifyOtp(phone: tPhone, token: tToken),
      ).called(1);
    });

    test(
      'should return Left(ServerFailure) when call throws exception',
      () async {
        when(
          () => mockRemoteDataSource.verifyOtp(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenThrow(Exception('error'));

        final result = await repository.verifyOtp(phone: tPhone, token: tToken);

        expect(result, isA<Left<Failure, AuthResponse>>());
        result.fold((l) {
          expect(l, isA<ServerFailure>());
          expect(l.message, 'Exception: error');
        }, (r) => fail('Expected Left'));
      },
    );
  });

  group('signOut', () {
    test(
      'should return Right(null) when call is successful and clear data',
      () async {
        when(
          () => mockRemoteDataSource.signOut(),
        ).thenAnswer((_) async => Future<void>.value());
        when(
          () => mockDataManagement.clearAllData(),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockSecureStorage.clearAll(),
        ).thenAnswer((_) async => Future<void>.value());

        final result = await repository.signOut();

        expect(result, const Right(null));
        verify(() => mockRemoteDataSource.signOut()).called(1);
        verify(() => mockDataManagement.clearAllData()).called(1);
        verify(() => mockSecureStorage.clearAll()).called(1);
      },
    );

    test(
      'should ignore data clearing exceptions and still return Right(null)',
      () async {
        when(
          () => mockRemoteDataSource.signOut(),
        ).thenAnswer((_) async => Future<void>.value());
        when(
          () => mockDataManagement.clearAllData(),
        ).thenThrow(Exception('Data clearing failed'));
        when(
          () => mockSecureStorage.clearAll(),
        ).thenThrow(Exception('Storage clearing failed'));

        final result = await repository.signOut();

        expect(result, const Right(null));
        verify(() => mockRemoteDataSource.signOut()).called(1);
        verify(() => mockDataManagement.clearAllData()).called(1);
        verify(() => mockSecureStorage.clearAll()).called(1);
      },
    );

    test(
      'should return Left(ServerFailure) when remote signOut throws exception',
      () async {
        when(
          () => mockRemoteDataSource.signOut(),
        ).thenThrow(Exception('error'));

        final result = await repository.signOut();

        expect(result, isA<Left<Failure, void>>());
      },
    );
  });

  group('getCurrentUser', () {
    test('should return Right(User) when remote data source returns user', () {
      final tUser = MockUser();
      when(() => mockRemoteDataSource.getCurrentUser()).thenReturn(tUser);

      final result = repository.getCurrentUser();

      expect(result, Right(tUser));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test('should return Right(null) when remote data source returns null', () {
      when(() => mockRemoteDataSource.getCurrentUser()).thenReturn(null);

      final result = repository.getCurrentUser();

      expect(result, const Right(null));
      verify(() => mockRemoteDataSource.getCurrentUser()).called(1);
    });

    test(
      'should return Left(CacheFailure) when remote data source throws exception',
      () {
        when(
          () => mockRemoteDataSource.getCurrentUser(),
        ).thenThrow(Exception('error'));

        final result = repository.getCurrentUser();

        expect(result, isA<Left<Failure, User?>>());
        result.fold((l) {
          expect(l, isA<CacheFailure>());
          expect(l.message, 'Exception: error');
        }, (r) => fail('Expected Left'));
      },
    );
  });

  group('authStateChanges', () {
    test('should return the stream from remote data source', () {
      final stream = Stream<AuthState>.empty();
      when(
        () => mockRemoteDataSource.authStateChanges,
      ).thenAnswer((_) => stream);

      final result = repository.authStateChanges;

      expect(result, stream);
      verify(() => mockRemoteDataSource.authStateChanges).called(1);
    });
  });
}
