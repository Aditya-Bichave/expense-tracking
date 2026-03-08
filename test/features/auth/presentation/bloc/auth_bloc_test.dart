import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_magic_link_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/login_with_otp_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/logout_usecase.dart';
import 'package:expense_tracker/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:expense_tracker/core/services/notification_service.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockLoginWithMagicLinkUseCase extends Mock
    implements LoginWithMagicLinkUseCase {}

class MockLoginWithOtpUseCase extends Mock implements LoginWithOtpUseCase {}

class MockVerifyOtpUseCase extends Mock implements VerifyOtpUseCase {}

class MockLogoutUseCase extends Mock implements LogoutUseCase {}

class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}

class MockNotificationService extends Mock implements NotificationService {}

void main() {
  late MockLoginWithMagicLinkUseCase mockMagicLink;
  late MockLoginWithOtpUseCase mockLoginOtp;
  late MockVerifyOtpUseCase mockVerifyOtp;
  late MockLogoutUseCase mockLogout;
  late MockGetCurrentUserUseCase mockGetCurrentUser;
  late MockNotificationService mockNotificationService;
  late AuthBloc bloc;

  final tUser = User(
    id: 'user_id',
    appMetadata: {},
    userMetadata: {},
    aud: 'authenticated',
    createdAt: DateTime.now().toIso8601String(),
  );

  setUp(() {
    mockMagicLink = MockLoginWithMagicLinkUseCase();
    mockLoginOtp = MockLoginWithOtpUseCase();
    mockVerifyOtp = MockVerifyOtpUseCase();
    mockLogout = MockLogoutUseCase();
    mockGetCurrentUser = MockGetCurrentUserUseCase();
    mockNotificationService = MockNotificationService();

    bloc = AuthBloc(
      mockLoginOtp,
      mockMagicLink,
      mockVerifyOtp,
      mockLogout,
      mockGetCurrentUser,
      mockNotificationService,
    );
    when(
      () => mockNotificationService.syncDeviceToken(),
    ).thenAnswer((_) async {});
    when(
      () => mockNotificationService.deleteDeviceToken(),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await bloc.close();
  });

  group('AuthBloc', () {
    test('initial state is AuthInitial', () {
      expect(bloc.state, isA<AuthInitial>());
    });

    test('AuthCheckStatus emits AuthAuthenticated when user exists', () async {
      when(() => mockGetCurrentUser()).thenReturn(Right(tUser));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([AuthAuthenticated(tUser)]),
      );

      bloc.add(AuthCheckStatus());
      await future;
    });

    test(
      'AuthCheckStatus emits AuthUnauthenticated when user is null',
      () async {
        when(() => mockGetCurrentUser()).thenReturn(const Right(null));

        final future = expectLater(
          bloc.stream,
          emitsInOrder([isA<AuthUnauthenticated>()]),
        );

        bloc.add(AuthCheckStatus());
        await future;
      },
    );

    test('AuthCheckStatus emits AuthUnauthenticated on failure', () async {
      when(
        () => mockGetCurrentUser(),
      ).thenReturn(const Left(ServerFailure('error')));

      final future = expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      bloc.add(AuthCheckStatus());
      await future;
    });

    test(
      'AuthLoginWithMagicLinkRequested emits loading then sent on right',
      () async {
        when(
          () => mockMagicLink(any()),
        ).thenAnswer((_) async => const Right(null));

        bloc.add(const AuthLoginWithMagicLinkRequested('test@test.com'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthMagicLinkSent>().having(
              (s) => s.email,
              'email',
              'test@test.com',
            ),
          ]),
        );

        verify(() => mockMagicLink('test@test.com')).called(1);
      },
    );

    test('AuthLoginWithMagicLinkRequested emits error on left', () async {
      when(
        () => mockMagicLink(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('error')));

      bloc.add(const AuthLoginWithMagicLinkRequested('test@test.com'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message', 'error'),
        ]),
      );
    });

    test('AuthLoginRequested emits loading then sent on right', () async {
      when(
        () => mockLoginOtp(any()),
      ).thenAnswer((_) async => const Right(null));

      bloc.add(const AuthLoginRequested('123'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthOtpSent>().having((s) => s.phone, 'phone', '123'),
        ]),
      );

      verify(() => mockLoginOtp('123')).called(1);
    });

    test('AuthLoginRequested emits error on left', () async {
      when(
        () => mockLoginOtp(any()),
      ).thenAnswer((_) async => const Left(ServerFailure('error')));

      bloc.add(const AuthLoginRequested('123'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message', 'error'),
        ]),
      );
    });

    test(
      'AuthVerifyOtpRequested emits loading then success when user is returned',
      () async {
        final tAuthResponse = AuthResponse(user: tUser, session: null);
        when(
          () => mockVerifyOtp(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => Right(tAuthResponse));

        bloc.add(const AuthVerifyOtpRequested('123', '456'));

        await expectLater(
          bloc.stream,
          emitsInOrder([isA<AuthLoading>(), AuthAuthenticated(tUser)]),
        );

        verify(() => mockVerifyOtp(phone: '123', token: '456')).called(1);
      },
    );

    test(
      'AuthVerifyOtpRequested emits error when user is null in response',
      () async {
        final tAuthResponse = AuthResponse(user: null, session: null);
        when(
          () => mockVerifyOtp(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async => Right(tAuthResponse));

        bloc.add(const AuthVerifyOtpRequested('123', '456'));

        await expectLater(
          bloc.stream,
          emitsInOrder([
            isA<AuthLoading>(),
            isA<AuthError>().having(
              (s) => s.message,
              'message',
              'Login failed: No user returned',
            ),
          ]),
        );
      },
    );

    test('AuthVerifyOtpRequested emits error on left', () async {
      when(
        () => mockVerifyOtp(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async => const Left(ServerFailure('error')));

      bloc.add(const AuthVerifyOtpRequested('123', '456'));

      await expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having((s) => s.message, 'message', 'error'),
        ]),
      );
    });

    test('AuthLogoutRequested emits loading then unauthenticated', () async {
      when(() => mockLogout()).thenAnswer((_) async => const Right(null));

      bloc.add(AuthLogoutRequested());

      await expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthLoading>(), isA<AuthUnauthenticated>()]),
      );

      verify(() => mockLogout()).called(1);
    });
  });
}
