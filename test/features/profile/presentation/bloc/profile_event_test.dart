import 'dart:io';
import 'package:expense_tracker/features/profile/presentation/bloc/profile_event.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ProfileEvent', () {
    test('FetchProfile supports value comparisons', () {
      expect(
        const FetchProfile(forceRefresh: true),
        equals(const FetchProfile(forceRefresh: true)),
      );
      expect(
        const FetchProfile(),
        equals(const FetchProfile(forceRefresh: false)),
      );
      expect(
        const FetchProfile(forceRefresh: true),
        isNot(equals(const FetchProfile(forceRefresh: false))),
      );
    });

    test('UpdateProfile supports value comparisons', () {
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
        const UpdateProfile(profile1),
        equals(const UpdateProfile(profile2)),
      );
      expect(
        const UpdateProfile(profile1),
        isNot(equals(const UpdateProfile(profile3))),
      );
    });

    test('UploadAvatar supports value comparisons', () {
      final file1 = File('path/to/file1.png');
      final file2 = File('path/to/file2.png');

      expect(UploadAvatar(file1), equals(UploadAvatar(file1)));
      expect(UploadAvatar(file1), isNot(equals(UploadAvatar(file2))));
    });
  });
}
