import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_expense_model.g.dart';

@HiveType(typeId: 11)
@JsonSerializable()
class GroupExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  @JsonKey(name: 'group_id')
  final String groupId;
  @HiveField(2)
  @JsonKey(name: 'created_by')
  final String createdBy;
  @HiveField(3)
  final String title;
  @HiveField(4)
  final double amount;
  @HiveField(5)
  final String currency;
  @HiveField(6)
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;
  @HiveField(7)
  final String? notes;

  GroupExpenseModel({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    this.notes,
  });

  factory GroupExpenseModel.fromEntity(GroupExpenseEntity entity) {
    return GroupExpenseModel(
      id: entity.id,
      groupId: entity.groupId,
      createdBy: entity.createdBy,
      title: entity.title,
      amount: entity.amount,
      currency: entity.currency,
      occurredAt: entity.occurredAt,
      notes: entity.notes,
    );
  }

  GroupExpenseEntity toEntity() {
    return GroupExpenseEntity(
      id: id,
      groupId: groupId,
      createdBy: createdBy,
      title: title,
      amount: amount,
      currency: currency,
      occurredAt: occurredAt,
      notes: notes,
    );
  }

  factory GroupExpenseModel.fromJson(Map<String, dynamic> json) => _$GroupExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$GroupExpenseModelToJson(this);
}
