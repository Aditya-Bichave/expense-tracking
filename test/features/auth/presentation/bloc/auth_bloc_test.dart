import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_otp_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_magic_link_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/logout_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;

class MockLoginWithOtpUseCase extends Mock implements LoginWithOtpUseCase {}

class MockLoginWithMagicLinkUseCase extends Mock
    implements LoginWithMagicLinkUseCase {}

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockUser extends Mock implements User {}

class FakeAuthResponse extends Fake implements AuthResponse {
  final User? _user;
  FakeAuthResponse({User? user}) : _user = user;
  @override
  User? get user => _user;
}

void main() {
  late AuthBloc bloc;
  late MockLoginWithOtpUseCase mockLoginUseCase;
  late MockLoginWithMagicLinkUseCase mockMagicLinkUseCase;
  late MockVerifyOtpUseCase mockVerifyUseCase;
  late MockLogoutUseCase mockLogoutUseCase;
  late MockGetCurrentUserUseCase mockGetCurrentUserUseCase;
  late MockUser mockUser;

  setUp(() {
    mockLoginUseCase = MockLoginWithOtpUseCase();
    mockMagicLinkUseCase = MockLoginWithMagicLinkUseCase();
    mockVerifyUseCase = MockVerifyOtpUseCase();
    mockLogoutUseCase = MockLogoutUseCase();
    mockGetCurrentUserUseCase = MockGetCurrentUserUseCase();
    mockUser = MockUser();

    bloc = AuthBloc(
      mockLoginUseCase,
      mockMagicLinkUseCase,
      mockVerifyUseCase,
      mockLogoutUseCase,
      mockGetCurrentUserUseCase,
    );
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(bloc.state, AuthInitial());
    });

    blocTest<AuthBloc, AuthState>(
      'emits [AuthAuthenticated] when check status returns user',
      setUp: () {
        when(() => mockGetCurrentUserUseCase()).thenReturn(Right(mockUser));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [AuthAuthenticated(mockUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthUnauthenticated] when check status returns null',
      setUp: () {
        when(() => mockGetCurrentUserUseCase()).thenReturn(const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AuthCheckStatus()),
      expect: () => [AuthUnauthenticated()],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthOtpSent] on successful login',
      setUp: () {
        when(
          () => mockLoginUseCase(any()),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AuthLoginRequested('123456')),
      expect: () => [AuthLoading(), AuthOtpSent('123456')],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthAuthenticated] on successful verify otp',
      setUp: () {
        when(
          () => mockVerifyUseCase(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => Right(FakeAuthResponse(user: mockUser)));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AuthVerifyOtpRequested('123456', '1234')),
      expect: () => [AuthLoading(), AuthAuthenticated(mockUser)],
    );

    blocTest<AuthBloc, AuthState>(
      'emits [AuthLoading, AuthUnauthenticated] on logout',
      setUp: () {
        when(
          () => mockLogoutUseCase(),
        ).thenAnswer((_) async => const Right(null));
      },
      build: () => bloc,
      act: (bloc) => bloc.add(AuthLogoutRequested()),
      expect: () => [AuthLoading(), AuthUnauthenticated()],
    );
  });
}
