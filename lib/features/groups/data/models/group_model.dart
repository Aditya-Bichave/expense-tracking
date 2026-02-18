import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_model.g.dart';

@HiveType(typeId: 13)
@JsonSerializable()
class GroupModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  @JsonKey(name: 'created_by')
  final String createdBy;

  @HiveField(3)
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @HiveField(4)
  @JsonKey(name: 'updated_at')
  final DateTime updatedAt;

  // We might not persist memberCount in Hive or it might be computed
  @JsonKey(ignore: true)
  final int memberCount;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.memberCount = 1,
  });

  factory GroupModel.fromEntity(GroupEntity entity) {
    return GroupModel(
      id: entity.id,
      name: entity.name,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      memberCount: entity.memberCount,
    );
  }

  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      name: name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      memberCount: memberCount,
    );
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _(json);

  Map<String, dynamic> toJson() => _(this);
}
