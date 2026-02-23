import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserProfile', () {
    const tUserProfile = UserProfile(
      id: '1',
      email: 'test@example.com',
      fullName: 'Test User',
      avatarUrl: 'https://example.com/avatar.png',
      currency: 'USD',
      timezone: 'UTC',
    );

    test('supports value comparisons', () {
      expect(
        tUserProfile,
        const UserProfile(
          id: '1',
          email: 'test@example.com',
          fullName: 'Test User',
          avatarUrl: 'https://example.com/avatar.png',
          currency: 'USD',
          timezone: 'UTC',
        ),
      );
    });
  });
}
