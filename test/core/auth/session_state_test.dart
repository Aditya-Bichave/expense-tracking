import 'package:expense_tracker/core/auth/session_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SessionState', () {
    test('SessionUnauthenticated supports value comparisons', () {
      expect(SessionUnauthenticated(), equals(SessionUnauthenticated()));
    });

    test('SessionAuthenticating supports value comparisons', () {
      expect(SessionAuthenticating(), equals(SessionAuthenticating()));
    });

    test('SessionAuthenticated supports value comparisons', () {
      const profile1 = UserProfile(
        id: '1',
        fullName: 'User 1',
        currency: 'USD',
        timezone: 'UTC',
      );
      const profile2 = UserProfile(
        id: '1',
        fullName: 'User 1',
        currency: 'USD',
        timezone: 'UTC',
      );
      const profile3 = UserProfile(
        id: '2',
        fullName: 'User 2',
        currency: 'EUR',
        timezone: 'UTC',
      );

      expect(
        const SessionAuthenticated(profile1),
        equals(const SessionAuthenticated(profile2)),
      );
      expect(
        const SessionAuthenticated(profile1),
        isNot(equals(const SessionAuthenticated(profile3))),
      );
    });

    test('SessionNeedsProfileSetup supports value comparisons', () {
      final user1 = User(
        id: '1',
        appMetadata: {},
        userMetadata: {},
        aud: 'auth',
        createdAt: '2023',
      );
      final user2 = User(
        id: '1',
        appMetadata: {},
        userMetadata: {},
        aud: 'auth',
        createdAt: '2023',
      );
      final user3 = User(
        id: '2',
        appMetadata: {},
        userMetadata: {},
        aud: 'auth',
        createdAt: '2023',
      );

      expect(
        SessionNeedsProfileSetup(user1),
        equals(SessionNeedsProfileSetup(user2)),
      );
      expect(
        SessionNeedsProfileSetup(user1),
        isNot(equals(SessionNeedsProfileSetup(user3))),
      );
    });

    test('SessionLocked supports value comparisons', () {
      expect(SessionLocked(), equals(SessionLocked()));
    });
  });
}
