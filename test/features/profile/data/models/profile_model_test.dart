import 'package:expense_tracker/features/profile/data/models/profile_model.dart';
import 'package:expense_tracker/features/profile/domain/entities/user_profile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tProfileModel = ProfileModel(
    id: '1',
    fullName: 'Test User',
    email: 'test@example.com',
    phone: '1234567890',
    avatarUrl: 'https://example.com/avatar.jpg',
    currency: 'USD',
    timezone: 'UTC',
  );

  const tUserProfile = UserProfile(
    id: '1',
    fullName: 'Test User',
    email: 'test@example.com',
    phone: '1234567890',
    avatarUrl: 'https://example.com/avatar.jpg',
    currency: 'USD',
    timezone: 'UTC',
  );

  group('ProfileModel', () {
    test('should be a subclass of UserProfile entity', () {
      expect(tProfileModel, isA<UserProfile>());
    });

    test('fromEntity should return a valid model', () {
      final result = ProfileModel.fromEntity(tUserProfile);
      expect(result, equals(tProfileModel));
    });

    test('fromJson should return a valid model using snake_case', () {
      final json = {
        'id': '1',
        'full_name': 'Test User',
        'email': 'test@example.com',
        'phone': '1234567890',
        'avatar_url': 'https://example.com/avatar.jpg',
        'currency': 'USD',
        'timezone': 'UTC',
      };

      final result = ProfileModel.fromJson(json);
      expect(result, equals(tProfileModel));
    });

    test(
      'toJson should return a JSON map containing proper data in snake_case',
      () {
        final result = tProfileModel.toJson();
        expect(result['id'], '1');
        expect(result['email'], 'test@example.com');
        expect(result['full_name'], 'Test User');
        expect(result['avatar_url'], 'https://example.com/avatar.jpg');
      },
    );
  });
}
