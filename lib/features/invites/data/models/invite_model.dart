import 'package:expense_tracker/features/invites/domain/entities/invite_entity.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'invite_model.g.dart';

@HiveType(typeId: 16)
@JsonSerializable()
class InviteModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'group_id')
  final String groupId;

  @HiveField(2)
  final String token;

  @HiveField(3)
  @JsonKey(name: 'expires_at')
  final DateTime expiresAt;

  @HiveField(4)
  @JsonKey(name: 'max_uses')
  final int maxUses;

  @HiveField(5)
  @JsonKey(name: 'uses_count')
  final int usesCount;

  InviteModel({
    required this.id,
    required this.groupId,
    required this.token,
    required this.expiresAt,
    required this.maxUses,
    required this.usesCount,
  });

  factory InviteModel.fromEntity(InviteEntity entity) {
    return InviteModel(
      id: entity.id,
      groupId: entity.groupId,
      token: entity.token,
      expiresAt: entity.expiresAt,
      maxUses: entity.maxUses,
      usesCount: entity.usesCount,
    );
  }

  InviteEntity toEntity() {
    return InviteEntity(
      id: id,
      groupId: groupId,
      token: token,
      expiresAt: expiresAt,
      maxUses: maxUses,
      usesCount: usesCount,
    );
  }

  factory InviteModel.fromJson(Map<String, dynamic> json) =>
      _(json);

  Map<String, dynamic> toJson() => _(this);
}
