import 'package:expense_tracker/features/groups/domain/entities/group_member.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 14)
class GroupMemberModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'group_id')
  final String groupId;

  @HiveField(2)
  @JsonKey(name: 'user_id')
  final String userId;

  @HiveField(3)
  @JsonKey(name: 'role')
  final String roleValue;

  @HiveField(4)
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;

  @HiveField(5)
  @JsonKey(name: 'updated_at') // Match DB column if snake_case
  final DateTime updatedAt;

  GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.roleValue,
    required this.joinedAt,
    required this.updatedAt,
  });

  factory GroupMemberModel.fromEntity(GroupMember entity) {
    return GroupMemberModel(
      id: entity.id,
      groupId: entity.groupId,
      userId: entity.userId,
      roleValue: entity.role.value,
      joinedAt: entity.joinedAt,
      updatedAt: entity.updatedAt,
    );
  }

  GroupMember toEntity() {
    return GroupMember(
      id: id,
      groupId: groupId,
      userId: userId,
      role: GroupRole.fromValue(roleValue),
      joinedAt: joinedAt,
      updatedAt: updatedAt,
    );
  }

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) {
    // Handle null updated_at by falling back to joined_at or now
    // But since we control migration, we should ensure it exists.
    // However, for safety:
    if (json['updated_at'] == null) {
      json['updated_at'] =
          json['joined_at'] ?? DateTime.now().toIso8601String();
    }
    return _$GroupMemberModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$GroupMemberModelToJson(this);
}
