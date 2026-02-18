import 'package:expense_tracker/features/groups/domain/entities/group_member_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_role.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_member_model.g.dart';

@HiveType(typeId: 12)
@JsonSerializable()
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
  final GroupRole role;
  @HiveField(4)
  @JsonKey(name: 'joined_at')
  final DateTime joinedAt;

  GroupMemberModel({
    required this.id,
    required this.groupId,
    required this.userId,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMemberModel.fromEntity(GroupMemberEntity entity) {
    return GroupMemberModel(
      id: entity.id,
      groupId: entity.groupId,
      userId: entity.userId,
      role: entity.role,
      joinedAt: entity.joinedAt,
    );
  }

  GroupMemberEntity toEntity() {
    return GroupMemberEntity(
      id: id,
      groupId: groupId,
      userId: userId,
      role: role,
      joinedAt: joinedAt,
    );
  }

  factory GroupMemberModel.fromJson(Map<String, dynamic> json) =>
      _$GroupMemberModelFromJson(json);
  Map<String, dynamic> toJson() => _$GroupMemberModelToJson(this);
}
