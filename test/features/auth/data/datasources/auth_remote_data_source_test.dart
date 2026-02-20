import 'package:expense_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class FakeAuthResponse extends Fake implements AuthResponse {}

void main() {
  late AuthRemoteDataSourceImpl dataSource;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;

  setUpAll(() {
    registerFallbackValue(OtpType.sms);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    dataSource = AuthRemoteDataSourceImpl(mockClient);
  });

  group('signInWithOtp', () {
    test('should call auth.signInWithOtp', () async {
      when(
        () => mockAuth.signInWithOtp(phone: any(named: 'phone')),
      ).thenAnswer((_) async => FakeAuthResponse());

      await dataSource.signInWithOtp(phone: '123456');

      verify(() => mockAuth.signInWithOtp(phone: '123456')).called(1);
    });
  });

  group('verifyOtp', () {
    test('should call auth.verifyOTP', () async {
      when(
        () => mockAuth.verifyOTP(
          type: any(named: 'type'),
          token: any(named: 'token'),
          phone: any(named: 'phone'),
        ),
      ).thenAnswer((_) async => FakeAuthResponse());

      await dataSource.verifyOtp(phone: '123456', token: '1234');

      verify(
        () => mockAuth.verifyOTP(
          type: OtpType.sms,
          token: '1234',
          phone: '123456',
        ),
      ).called(1);
    });
  });

  group('signOut', () {
    test('should call auth.signOut', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});

      await dataSource.signOut();

      verify(() => mockAuth.signOut()).called(1);
    });
  });

  group('getCurrentUser', () {
    test('should return auth.currentUser', () {
      final mockUser = MockUser();
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final result = dataSource.getCurrentUser();

      expect(result, mockUser);
    });
  });

  group('authStateChanges', () {
    test('should return auth.onAuthStateChange', () {
      final stream = Stream<AuthState>.empty();
      when(() => mockAuth.onAuthStateChange).thenAnswer((_) => stream);

      final result = dataSource.authStateChanges;

      expect(result, stream);
    });
  });
}
