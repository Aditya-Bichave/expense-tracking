import 'package:expense_tracker/features/profile/presentation/bloc/profile_state.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileState', () {
    test('ProfileInitial supports value comparisons', () {
      expect(ProfileInitial(), equals(ProfileInitial()));
    });

    test('ProfileLoading supports value comparisons', () {
      expect(ProfileLoading(), equals(ProfileLoading()));
    });

    test('ProfileLoaded supports value comparisons', () {
      const profile1 = UserProfile(
        id: '1',
        fullName: 'User 1',
        email: 'user1@example.com',
        currency: 'USD',
        timezone: 'UTC',
      );
      const profile2 = UserProfile(
        id: '1',
        fullName: 'User 1',
        email: 'user1@example.com',
        currency: 'USD',
        timezone: 'UTC',
      );
      const profile3 = UserProfile(
        id: '2',
        fullName: 'User 2',
        email: 'user2@example.com',
        currency: 'EUR',
        timezone: 'UTC',
      );

      expect(ProfileLoaded(profile1), equals(ProfileLoaded(profile2)));
      expect(ProfileLoaded(profile1), isNot(equals(ProfileLoaded(profile3))));
    });

    test('ProfileError supports value comparisons', () {
      expect(const ProfileError('error'), equals(const ProfileError('error')));
      expect(
        const ProfileError('error1'),
        isNot(equals(const ProfileError('error2'))),
      );
    });
  });
}
