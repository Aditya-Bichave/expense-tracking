import 'package:expense_tracker/features/groups/domain/entities/group_expense_entity.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_expense_model.g.dart';

@HiveType(typeId: 15)
@JsonSerializable()
class GroupExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  @JsonKey(name: 'group_id')
  final String groupId;

  @HiveField(2)
  final String title;

  @HiveField(3)
  final double amount;

  @HiveField(4)
  final String currency;

  @HiveField(5)
  @JsonKey(name: 'occurred_at')
  final DateTime occurredAt;

  @HiveField(6)
  @JsonKey(name: 'created_by')
  final String createdBy;

  GroupExpenseModel({
    required this.id,
    required this.groupId,
    required this.title,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.createdBy,
  });

  factory GroupExpenseModel.fromEntity(GroupExpenseEntity entity) {
    return GroupExpenseModel(
      id: entity.id,
      groupId: entity.groupId,
      title: entity.title,
      amount: entity.amount,
      currency: entity.currency,
      occurredAt: entity.occurredAt,
      createdBy: entity.createdBy,
    );
  }

  GroupExpenseEntity toEntity() {
    return GroupExpenseEntity(
      id: id,
      groupId: groupId,
      title: title,
      amount: amount,
      currency: currency,
      occurredAt: occurredAt,
      createdBy: createdBy,
    );
  }

  factory GroupExpenseModel.fromJson(Map<String, dynamic> json) =>
      _(json);

  Map<String, dynamic> toJson() => _(this);
}
