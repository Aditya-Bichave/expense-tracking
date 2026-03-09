import 'package:expense_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AuthEvent', () {
    test('AuthLoginRequested supports value comparisons', () {
      expect(
        const AuthLoginRequested('123'),
        equals(const AuthLoginRequested('123')),
      );
      expect(
        const AuthLoginRequested('123'),
        isNot(equals(const AuthLoginRequested('456'))),
      );
    });

    test('AuthVerifyOtpRequested supports value comparisons', () {
      expect(
        const AuthVerifyOtpRequested('123', 'tok'),
        equals(const AuthVerifyOtpRequested('123', 'tok')),
      );
      expect(
        const AuthVerifyOtpRequested('123', 'tok'),
        isNot(equals(const AuthVerifyOtpRequested('456', 'tok'))),
      );
    });

    test('AuthLogoutRequested supports value comparisons', () {
      expect(AuthLogoutRequested(), equals(AuthLogoutRequested()));
    });

    test('AuthCheckStatus supports value comparisons', () {
      expect(AuthCheckStatus(), equals(AuthCheckStatus()));
    });

    test('AuthLoginWithMagicLinkRequested supports value comparisons', () {
      expect(
        const AuthLoginWithMagicLinkRequested('e@m.com'),
        equals(const AuthLoginWithMagicLinkRequested('e@m.com')),
      );
      expect(
        const AuthLoginWithMagicLinkRequested('e@m.com'),
        isNot(equals(const AuthLoginWithMagicLinkRequested('e2@m.com'))),
      );
    });
  });
}
