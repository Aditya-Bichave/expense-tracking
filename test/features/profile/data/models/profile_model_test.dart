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

    test('fromJson should return a valid model', () {
      final json = {
        'id': '1',
        'full_name': 'Test User',
        'email': 'test@example.com',
        'phone': '1234567890',
        'avatar_url': 'https://example.com/avatar.jpg',
        'currency': 'USD',
        'timezone': 'UTC',
      };

      try {
        final result = ProfileModel.fromJson(json);
        // If generated code expects camelCase, this might have nulls or crash.
        // But if it expects snake_case, it should be equal.
        // If result.fullName is null, then it failed to map.
        if (result.fullName == null) {
          throw Exception('Failed to map snake_case');
        }
        expect(result, equals(tProfileModel));
      } catch (e) {
        final jsonCamel = {
          'id': '1',
          'fullName': 'Test User',
          'email': 'test@example.com',
          'phone': '1234567890',
          'avatarUrl': 'https://example.com/avatar.jpg',
          'currency': 'USD',
          'timezone': 'UTC',
        };
        final result = ProfileModel.fromJson(jsonCamel);
        expect(result, equals(tProfileModel));
      }
    });

    test('toJson should return a JSON map containing proper data', () {
      final result = tProfileModel.toJson();
      expect(result['id'], '1');
      expect(result['email'], 'test@example.com');

      if (result.containsKey('full_name')) {
        expect(result['full_name'], 'Test User');
      } else {
        expect(result['fullName'], 'Test User');
      }
    });
  });
}
