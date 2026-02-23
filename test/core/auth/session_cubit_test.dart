import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/auth/session_cubit.dart';
import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:expense_tracker/features/profile/domain/repositories/profile_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../helpers/core_mocks.dart';
import '../../helpers/mock_helpers.dart';

// Create a Fake User because mocking User might be hard with final fields
class FakeUser extends Fake implements User {
  @override
  String get id => '123';
  @override
  String get email => 'test@example.com';
}

void main() {
  late MockAuthRepository authRepository;
  late MockProfileRepository profileRepository;
  late MockSecureStorageService secureStorageService;
  late SessionCubit sessionCubit;
  // ignore: close_sinks
  late StreamController<AuthState> authStateController;

  final user = FakeUser();
  final profile = const UserProfile(
    id: '1',
    email: 'test@example.com',
    fullName: 'Test User',
    currency: 'USD',
    timezone: 'UTC',
  );
  // ignore: unused_local_variable
  final incompleteProfile = const UserProfile(
    id: '1',
    email: 'test@example.com',
    fullName: '',
    currency: 'USD',
    timezone: 'UTC',
  );

  setUpAll(() {
    registerFallbackValue(SessionUnauthenticated());
    registerFallbackValue(
      const SessionAuthenticated(
        UserProfile(
          id: '1',
          email: 'test@example.com',
          fullName: 'Test User',
          currency: 'USD',
          timezone: 'UTC',
        ),
      ),
    );
  });

  setUp(() {
    authRepository = MockAuthRepository();
    profileRepository = MockProfileRepository();
    secureStorageService = MockSecureStorageService();
    authStateController = StreamController<AuthState>.broadcast();

    when(
      () => authRepository.authStateChanges,
    ).thenAnswer((_) => authStateController.stream);

    // Default mock behavior
    when(
      () => secureStorageService.isBiometricEnabled(),
    ).thenAnswer((_) async => false);
  });

  tearDown(() {
    authStateController.close();
    // Only close if it was initialized
    try {
      sessionCubit.close();
    } catch (_) {}
  });

  SessionCubit buildCubit() {
    sessionCubit = SessionCubit(
      authRepository,
      profileRepository,
      secureStorageService,
    );
    return sessionCubit;
  }

  group('SessionCubit', () {
    test('initial state is SessionUnauthenticated', () {
      buildCubit();
      expect(sessionCubit.state, SessionUnauthenticated());
    });

    blocTest<SessionCubit, SessionState>(
      'emits SessionUnauthenticated when signed out event is received',
      build: buildCubit,
      act: (cubit) async {
        authStateController.add(AuthState(AuthChangeEvent.signedOut, null));
        await Future.delayed(Duration.zero);
      },
      expect: () => [SessionUnauthenticated()],
    );

    blocTest<SessionCubit, SessionState>(
      'checkSession emits SessionUnauthenticated when no user is logged in',
      build: () {
        when(
          () => authRepository.getCurrentUser(),
        ).thenReturn(const Left(AuthenticationFailure('No user')));
        return buildCubit();
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [SessionUnauthenticated()],
    );

    blocTest<SessionCubit, SessionState>(
      'checkSession emits SessionLocked when biometric is enabled',
      build: () {
        when(() => authRepository.getCurrentUser()).thenReturn(Right(user));
        when(
          () => secureStorageService.isBiometricEnabled(),
        ).thenAnswer((_) async => true);
        return buildCubit();
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [SessionLocked()],
    );

    blocTest<SessionCubit, SessionState>(
      'checkSession emits SessionAuthenticated when user and profile exist',
      build: () {
        when(() => authRepository.getCurrentUser()).thenReturn(Right(user));
        when(
          () => profileRepository.getProfile(forceRefresh: false),
        ).thenAnswer((_) async => Right(profile));
        when(
          () => profileRepository.getProfile(forceRefresh: true),
        ).thenAnswer((_) async => Right(profile));
        return buildCubit();
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [SessionAuthenticated(profile)],
    );

    blocTest<SessionCubit, SessionState>(
      'checkSession emits SessionAuthenticated after local fail but remote success',
      build: () {
        when(() => authRepository.getCurrentUser()).thenReturn(Right(user));
        when(
          () => profileRepository.getProfile(forceRefresh: false),
        ).thenAnswer((_) async => const Left(CacheFailure('Fail')));
        when(
          () => profileRepository.getProfile(forceRefresh: true),
        ).thenAnswer((_) async => Right(profile));
        return buildCubit();
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [SessionAuthenticated(profile)],
    );

    blocTest<SessionCubit, SessionState>(
      'checkSession emits SessionNeedsProfileSetup when profile is incomplete',
      build: () {
        when(() => authRepository.getCurrentUser()).thenReturn(Right(user));
        when(
          () => profileRepository.getProfile(forceRefresh: false),
        ).thenAnswer((_) async => Right(incompleteProfile));
        when(
          () => profileRepository.getProfile(forceRefresh: true),
        ).thenAnswer((_) async => Right(incompleteProfile));
        return buildCubit();
      },
      act: (cubit) => cubit.checkSession(),
      expect: () => [SessionNeedsProfileSetup(user)],
    );

    blocTest<SessionCubit, SessionState>(
      'unlock emits SessionAuthenticated when successful',
      build: () {
        when(() => authRepository.getCurrentUser()).thenReturn(Right(user));
        when(
          () => profileRepository.getProfile(forceRefresh: false),
        ).thenAnswer((_) async => Right(profile));
        when(
          () => profileRepository.getProfile(forceRefresh: true),
        ).thenAnswer((_) async => Right(profile));
        return buildCubit();
      },
      act: (cubit) => cubit.unlock(),
      expect: () => [SessionAuthenticated(profile)],
    );

    blocTest<SessionCubit, SessionState>(
      'lock emits SessionLocked',
      build: buildCubit,
      act: (cubit) => cubit.lock(),
      expect: () => [SessionLocked()],
    );
  });
}
