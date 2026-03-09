import 'package:expense_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthState', () {
    test('AuthInitial supports value comparisons', () {
      expect(AuthInitial(), equals(AuthInitial()));
    });

    test('AuthLoading supports value comparisons', () {
      expect(AuthLoading(), equals(AuthLoading()));
    });

    test('AuthOtpSent supports value comparisons', () {
      expect(const AuthOtpSent('123'), equals(const AuthOtpSent('123')));
      expect(const AuthOtpSent('123'), isNot(equals(const AuthOtpSent('456'))));
    });

    test('AuthAuthenticated supports value comparisons', () {
      final user1 = User(
        id: '1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2023-01-01',
      );
      final user2 = User(
        id: '1',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2023-01-01',
      );
      final user3 = User(
        id: '2',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: '2023-01-01',
      );

      expect(AuthAuthenticated(user1), equals(AuthAuthenticated(user2)));
      expect(AuthAuthenticated(user1), isNot(equals(AuthAuthenticated(user3))));
    });

    test('AuthUnauthenticated supports value comparisons', () {
      expect(AuthUnauthenticated(), equals(AuthUnauthenticated()));
    });

    test('AuthError supports value comparisons', () {
      expect(const AuthError('error'), equals(const AuthError('error')));
      expect(
        const AuthError('error1'),
        isNot(equals(const AuthError('error2'))),
      );
    });

    test('AuthMagicLinkSent supports value comparisons', () {
      expect(
        const AuthMagicLinkSent('test@test.com'),
        equals(const AuthMagicLinkSent('test@test.com')),
      );
      expect(
        const AuthMagicLinkSent('test@test.com'),
        isNot(equals(const AuthMagicLinkSent('test2@test.com'))),
      );
    });
  });
}
