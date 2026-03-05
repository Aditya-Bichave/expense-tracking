import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockUser extends Mock implements User {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRemoteDataSourceImpl dataSource;

  setUpAll(() {
    registerFallbackValue(OtpType.sms);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockClient.auth).thenReturn(mockAuth);

    dataSource = AuthRemoteDataSourceImpl(mockClient);
  });

  group('AuthRemoteDataSourceImpl', () {
    const tPhone = '1234567890';
    const tEmail = 'test@example.com';
    const tToken = '123456';

    test('signInWithOtp calls correct client method', () async {
      when(
        () => mockAuth.signInWithOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async => Future.value());

      await dataSource.signInWithOtp(phone: tPhone);

      verify(() => mockAuth.signInWithOtp(phone: tPhone)).called(1);
    });

    test('signInWithMagicLink calls correct client method', () async {
      when(
        () => mockAuth.signInWithOtp(
          email: any(named: 'email'),
          emailRedirectTo: any(named: 'emailRedirectTo'),
        ),
      ).thenAnswer((_) async => Future.value());

      await dataSource.signInWithMagicLink(email: tEmail);

      verify(
        () => mockAuth.signInWithOtp(
          email: tEmail,
          emailRedirectTo: 'io.supabase.expensetracker://login-callback',
        ),
      ).called(1);
    });

    test(
      'signInAnonymously calls correct client method and returns response',
      () async {
        final tResponse = MockAuthResponse();
        when(
          () => mockAuth.signInAnonymously(),
        ).thenAnswer((_) async => tResponse);

        final result = await dataSource.signInAnonymously();

        expect(result, equals(tResponse));
        verify(() => mockAuth.signInAnonymously()).called(1);
      },
    );

    test(
      'verifyOtp calls correct client method and returns response',
      () async {
        final tResponse = MockAuthResponse();
        when(
          () => mockAuth.verifyOTP(
            type: any(named: 'type'),
            token: any(named: 'token'),
            phone: any(named: 'phone'),
          ),
        ).thenAnswer((_) async => tResponse);

        final result = await dataSource.verifyOtp(phone: tPhone, token: tToken);

        expect(result, equals(tResponse));
        verify(
          () => mockAuth.verifyOTP(
            type: OtpType.sms,
            token: tToken,
            phone: tPhone,
          ),
        ).called(1);
      },
    );

    test('signOut calls correct client method', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async => Future.value());

      await dataSource.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });

    test('getCurrentUser returns user from client', () {
      final tUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(tUser);

      final result = dataSource.getCurrentUser();

      expect(result, equals(tUser));
      verify(() => mockAuth.currentUser).called(1);
    });

    test('authStateChanges returns stream from client', () {
      final stream = Stream<AuthState>.empty();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => stream);

      final result = dataSource.authStateChanges;

      expect(result, equals(stream));
      verify(() => mockAuth.onAuthStateChange).called(1);
    });
  });
}
