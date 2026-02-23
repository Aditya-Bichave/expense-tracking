import 'dart:io';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/domain/usecases/get_profile_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/update_profile_usecase.dart';
import 'package:expense_tracker/features/profile/domain/usecases/upload_avatar_usecase.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_event.dart';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetProfileUseCase extends Mock implements GetProfileUseCase {}

class MockUpdateProfileUseCase extends Mock implements UpdateProfileUseCase {}

class MockUploadAvatarUseCase extends Mock implements UploadAvatarUseCase {}

class FakeUserProfile extends Fake implements UserProfile {}

class FakeFile extends Fake implements File {}

void main() {
  late ProfileBloc bloc;
  late MockGetProfileUseCase mockGetProfileUseCase;
  late MockUpdateProfileUseCase mockUpdateProfileUseCase;
  late MockUploadAvatarUseCase mockUploadAvatarUseCase;

  setUpAll(() {
    registerFallbackValue(FakeUserProfile());
    registerFallbackValue(FakeFile());
  });

  setUp(() {
    mockGetProfileUseCase = MockGetProfileUseCase();
    mockUpdateProfileUseCase = MockUpdateProfileUseCase();
    mockUploadAvatarUseCase = MockUploadAvatarUseCase();
    bloc = ProfileBloc(
      mockGetProfileUseCase,
      mockUpdateProfileUseCase,
      mockUploadAvatarUseCase,
    );
  });

  const tProfile = UserProfile(
    id: '1',
    fullName: 'Test User',
    currency: 'USD',
    timezone: 'UTC',
  );

  group('ProfileBloc', () {
    test('initial state is ProfileInitial', () {
      expect(bloc.state, ProfileInitial());
    });

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] when FetchProfile is added',
      build: () {
        when(
          () => mockGetProfileUseCase(forceRefresh: any(named: 'forceRefresh')),
        ).thenAnswer((_) async => const Right(tProfile));
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchProfile()),
      expect: () => [ProfileLoading(), const ProfileLoaded(tProfile)],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileError] when FetchProfile fails',
      build: () {
        when(
          () => mockGetProfileUseCase(forceRefresh: any(named: 'forceRefresh')),
        ).thenAnswer((_) async => const Left(ServerFailure('Error')));
        return bloc;
      },
      act: (bloc) => bloc.add(const FetchProfile()),
      expect: () => [ProfileLoading(), const ProfileError('Error')],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] when UpdateProfile is added',
      build: () {
        when(
          () => mockUpdateProfileUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(const UpdateProfile(tProfile)),
      expect: () => [ProfileLoading(), const ProfileLoaded(tProfile)],
    );

    blocTest<ProfileBloc, ProfileState>(
      'emits [ProfileLoading, ProfileLoaded] with new avatar when UploadAvatar is added',
      seed: () => const ProfileLoaded(tProfile),
      build: () {
        when(
          () => mockUploadAvatarUseCase(any()),
        ).thenAnswer((_) async => const Right('new_url'));
        when(
          () => mockUpdateProfileUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
        return bloc;
      },
      act: (bloc) => bloc.add(UploadAvatar(FakeFile())),
      verify: (_) {
        verify(() => mockUploadAvatarUseCase(any())).called(1);
        verify(() => mockUpdateProfileUseCase(any())).called(1);
      },
      expect: () => [
        ProfileLoading(),
        isA<ProfileLoaded>().having(
          (s) => s.profile.avatarUrl,
          'avatarUrl',
          'new_url',
        ),
      ],
    );
  });
}
