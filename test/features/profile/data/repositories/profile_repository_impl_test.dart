import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_local_data_source.dart';
import 'package:expense_tracker/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockProfileLocalDataSource extends Mock
    implements ProfileLocalDataSource {}

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late ProfileRepositoryImpl repository;
  late MockProfileLocalDataSource mockLocalDataSource;
  late MockProfileRemoteDataSource mockRemoteDataSource;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockLocalDataSource = MockProfileLocalDataSource();
    mockRemoteDataSource = MockProfileRemoteDataSource();
    mockAuthRepository = MockAuthRepository();
    repository = ProfileRepositoryImpl(
      mockRemoteDataSource,
      mockLocalDataSource,
      mockAuthRepository,
    );
  });

  const tProfileModel = ProfileModel(
    id: '123',
    fullName: 'Test User',
    currency: 'USD',
    timezone: 'UTC',
  );

  group('getProfile', () {
    test(
      'should return cached profile if available and forceRefresh is false',
      () async {
        // arrange
        when(
          () => mockLocalDataSource.getLastProfile(),
        ).thenAnswer((_) async => tProfileModel);
        // act
        final result = await repository.getProfile(forceRefresh: false);
        // assert
        verify(() => mockLocalDataSource.getLastProfile());
        verifyZeroInteractions(mockRemoteDataSource);
        expect(result, equals(const Right(tProfileModel)));
      },
    );

    test('should fetch from remote if cache is empty', () async {
      // arrange
      when(
        () => mockLocalDataSource.getLastProfile(),
      ).thenAnswer((_) async => null);
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('123');
      when(
        () => mockAuthRepository.getCurrentUser(),
      ).thenReturn(Right(mockUser));
      when(
        () => mockRemoteDataSource.getProfile('123'),
      ).thenAnswer((_) async => tProfileModel);
      when(
        () => mockLocalDataSource.cacheProfile(tProfileModel),
      ).thenAnswer((_) async => {});

      // act
      final result = await repository.getProfile(forceRefresh: false);

      // assert
      verify(() => mockLocalDataSource.getLastProfile());
      verify(() => mockRemoteDataSource.getProfile('123'));
      verify(() => mockLocalDataSource.cacheProfile(tProfileModel));
      expect(result, equals(const Right(tProfileModel)));
    });
  });
}
