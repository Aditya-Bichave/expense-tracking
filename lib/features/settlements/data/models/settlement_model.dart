import 'package:expense_tracker/features/settlements/domain/entities/settlement.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settlement_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 16)
class SettlementModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String groupId;
  @HiveField(2)
  final String fromUserId;
  @HiveField(3)
  final String toUserId;
  @HiveField(4)
  final double amount;
  @HiveField(5)
  final String currency;
  @HiveField(6)
  final DateTime createdAt;

  SettlementModel({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.currency,
    required this.createdAt,
  });

  factory SettlementModel.fromEntity(Settlement entity) {
    return SettlementModel(
      id: entity.id,
      groupId: entity.groupId,
      fromUserId: entity.fromUserId,
      toUserId: entity.toUserId,
      amount: entity.amount,
      currency: entity.currency,
      createdAt: entity.createdAt,
    );
  }

  Settlement toEntity() {
    return Settlement(
      id: id,
      groupId: groupId,
      fromUserId: fromUserId,
      toUserId: toUserId,
      amount: amount,
      currency: currency,
      createdAt: createdAt,
    );
  }

  factory SettlementModel.fromJson(Map<String, dynamic> json) =>
      _$SettlementModelFromJson(json);
  Map<String, dynamic> toJson() => _$SettlementModelToJson(this);
}
