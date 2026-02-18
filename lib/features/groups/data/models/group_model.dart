import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_model.g.dart';

@HiveType(typeId: 10)
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

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GroupModel.fromEntity(GroupEntity entity) {
    return GroupModel(
      id: entity.id,
      name: entity.name,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }

  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      name: name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);
  Map<String, dynamic> toJson() => _$GroupModelToJson(this);
}
