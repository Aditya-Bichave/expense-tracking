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
  final String groupId;

  @HiveField(2)
  final String userId;

  @HiveField(3)
  final String roleValue;

  @HiveField(4)
  final DateTime joinedAt;

  GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.roleValue,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromEntity(GroupMember entity) {
    return GroupMemberModel(
      id: entity.id,
      groupId: entity.groupId,
      userId: entity.userId,
      roleValue: entity.role.value,
      joinedAt: entity.joinedAt,
    );
  }

  GroupMember toEntity() {
    return GroupMember(
      id: id,
      groupId: groupId,
      userId: userId,
      role: GroupRole.fromValue(roleValue),
      joinedAt: joinedAt,
    );
  }

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupMemberModelToJson(this);
}
