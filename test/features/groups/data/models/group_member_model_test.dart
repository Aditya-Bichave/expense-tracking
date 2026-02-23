import 'package:expense_tracker/features/groups/data/models/group_member_model.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final tJoinedAt = DateTime(2023, 1, 1).toUtc();
  final tUpdatedAt = DateTime(2023, 1, 2).toUtc();

  final tGroupMemberModel = GroupMemberModel(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    roleValue: 'admin',
    joinedAt: tJoinedAt,
    updatedAt: tUpdatedAt,
  );

  final tGroupMember = GroupMember(
    id: 'm1',
    groupId: 'g1',
    userId: 'u1',
    role: GroupRole.admin,
    joinedAt: tJoinedAt,
    updatedAt: tUpdatedAt,
  );

  group('GroupMemberModel', () {
    test('fromEntity should return a valid model', () {
      final result = GroupMemberModel.fromEntity(tGroupMember);

      expect(result.id, tGroupMemberModel.id);
      expect(result.groupId, tGroupMemberModel.groupId);
      expect(result.userId, tGroupMemberModel.userId);
      expect(result.roleValue, tGroupMemberModel.roleValue);
      expect(result.joinedAt, tGroupMemberModel.joinedAt);
      expect(result.updatedAt, tGroupMemberModel.updatedAt);
    });

    test('toEntity should return a valid entity', () {
      final result = tGroupMemberModel.toEntity();

      expect(result, equals(tGroupMember));
    });

    test('fromJson should return a valid model when JSON is correct', () {
      final Map<String, dynamic> jsonMap = {
        'id': 'm1',
        'group_id': 'g1',
        'user_id': 'u1',
        'role': 'admin',
        'joined_at': tJoinedAt.toIso8601String(),
        'updated_at': tUpdatedAt.toIso8601String(),
      };

      final result = GroupMemberModel.fromJson(jsonMap);

      expect(result.id, tGroupMemberModel.id);
      expect(result.joinedAt, tGroupMemberModel.joinedAt);
      expect(result.updatedAt, tGroupMemberModel.updatedAt);
    });

    test('fromJson should fallback updated_at to joined_at if missing', () {
      final Map<String, dynamic> jsonMap = {
        'id': 'm1',
        'group_id': 'g1',
        'user_id': 'u1',
        'role': 'admin',
        'joined_at': tJoinedAt.toIso8601String(),
        // missing updated_at
      };

      final result = GroupMemberModel.fromJson(jsonMap);

      expect(result.id, tGroupMemberModel.id);
      expect(result.updatedAt, tGroupMemberModel.joinedAt);
    });

    test('toJson should return a JSON map containing proper data', () {
      final result = tGroupMemberModel.toJson();

      final expectedMap = {
        'id': 'm1',
        'group_id': 'g1',
        'user_id': 'u1',
        'role': 'admin',
        'joined_at': tJoinedAt.toIso8601String(),
        'updated_at': tUpdatedAt.toIso8601String(),
      };

      expect(result, equals(expectedMap));
    });
  });
}
