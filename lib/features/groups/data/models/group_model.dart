import 'package:expense_tracker/features/groups/domain/entities/group_entity.dart';
import 'package:expense_tracker/features/groups/domain/entities/group_type.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 13)
class GroupModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String createdBy;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  final DateTime updatedAt;

  @HiveField(5, defaultValue: 'custom')
  @JsonKey(defaultValue: 'custom')
  final String typeValue;

  @HiveField(6, defaultValue: 'USD')
  @JsonKey(defaultValue: 'USD')
  final String currency;

  @HiveField(7)
  final String? photoUrl;

  @HiveField(8, defaultValue: false)
  @JsonKey(defaultValue: false)
  final bool isArchived;

  GroupModel({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    required this.typeValue,
    required this.currency,
    this.photoUrl,
    this.isArchived = false,
  });

  factory GroupModel.fromEntity(GroupEntity entity) {
    return GroupModel(
      id: entity.id,
      name: entity.name,
      createdBy: entity.createdBy,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      typeValue: entity.type.value,
      currency: entity.currency,
      photoUrl: entity.photoUrl,
      isArchived: entity.isArchived,
    );
  }

  GroupEntity toEntity() {
    return GroupEntity(
      id: id,
      name: name,
      createdBy: createdBy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      type: GroupType.fromValue(typeValue),
      currency: currency,
      photoUrl: photoUrl,
      isArchived: isArchived,
    );
  }

  factory GroupModel.fromJson(Map<String, dynamic> json) =>
      _$GroupModelFromJson(json);

  Map<String, dynamic> toJson() => _$GroupModelToJson(this);
}
