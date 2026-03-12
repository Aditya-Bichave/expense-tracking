import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/groups/data/models/group_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';

void main() {
  group('GroupModel', () {
    final dateTime = DateTime.parse('2023-01-01T00:00:00.000Z');

    final tGroupModel = GroupModel(
      id: 'g1',
      name: 'Test Group',
      createdBy: 'u1',
      createdAt: dateTime,
      updatedAt: dateTime,
      typeValue: 'trip',
      currency: 'USD',
      photoUrl: 'http://example.com/photo.jpg',
      isArchived: false,
    );

    final tGroupEntity = GroupEntity(
      id: 'g1',
      name: 'Test Group',
      createdBy: 'u1',
      createdAt: dateTime,
      updatedAt: dateTime,
      type: GroupType.trip,
      currency: 'USD',
      photoUrl: 'http://example.com/photo.jpg',
      isArchived: false,
    );

    test('fromEntity converts correctly', () {
      final model = GroupModel.fromEntity(tGroupEntity);
      expect(model.id, tGroupModel.id);
      expect(model.name, tGroupModel.name);
      expect(model.createdBy, tGroupModel.createdBy);
      expect(model.createdAt, tGroupModel.createdAt);
      expect(model.updatedAt, tGroupModel.updatedAt);
      expect(model.typeValue, tGroupModel.typeValue);
      expect(model.currency, tGroupModel.currency);
      expect(model.photoUrl, tGroupModel.photoUrl);
      expect(model.isArchived, tGroupModel.isArchived);
    });

    test('toEntity converts correctly', () {
      final entity = tGroupModel.toEntity();
      expect(entity, tGroupEntity);
    });

    test('fromJson creates a valid model', () {
      final Map<String, dynamic> jsonMap = {
        'id': 'g1',
        'name': 'Test Group',
        'created_by': 'u1',
        'created_at': dateTime.toIso8601String(),
        'updated_at': dateTime.toIso8601String(),
        'type': 'trip',
        'currency': 'USD',
        'photo_url': 'http://example.com/photo.jpg',
        'is_archived': false,
      };

      final result = GroupModel.fromJson(jsonMap);

      expect(result.id, tGroupModel.id);
      expect(result.name, tGroupModel.name);
      expect(result.createdBy, tGroupModel.createdBy);
      expect(result.createdAt, tGroupModel.createdAt);
      expect(result.updatedAt, tGroupModel.updatedAt);
      expect(result.typeValue, tGroupModel.typeValue);
      expect(result.currency, tGroupModel.currency);
      expect(result.photoUrl, tGroupModel.photoUrl);
      expect(result.isArchived, tGroupModel.isArchived);
    });

    test('toJson returns a JSON map containing proper data', () {
      final expectedMap = {
        'id': 'g1',
        'name': 'Test Group',
        'created_by': 'u1',
        'created_at': dateTime.toIso8601String(),
        'updated_at': dateTime.toIso8601String(),
        'type': 'trip',
        'currency': 'USD',
        'photo_url': 'http://example.com/photo.jpg',
        'is_archived': false,
      };

      final result = tGroupModel.toJson();

      expect(result, expectedMap);
    });

    test('toUpdateJson returns only editable snake_case fields', () {
      final result = tGroupModel.toUpdateJson();

      expect(result, {
        'name': 'Test Group',
        'type': 'trip',
        'currency': 'USD',
        'photo_url': 'http://example.com/photo.jpg',
        'updated_at': dateTime.toIso8601String(),
        'is_archived': false,
      });
    });
  });
}
