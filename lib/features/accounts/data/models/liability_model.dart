import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability.dart';
import 'package:expense_tracker/features/accounts/domain/entities/liability_enums.dart';

part 'liability_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 2)
class LiabilityModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String? userId;

  @HiveField(2)
  final String name;

  @HiveField(3)
  final int typeIndex;

  @HiveField(4)
  final double initialBalance;

  @HiveField(5)
  final double? creditLimit;

  @HiveField(6)
  final double? interestRate;

  @HiveField(7)
  final DateTime createdAt;

  LiabilityModel({
    required this.id,
    this.userId,
    required this.name,
    required this.typeIndex,
    required this.initialBalance,
    this.creditLimit,
    this.interestRate,
    required this.createdAt,
  });

  factory LiabilityModel.fromEntity(Liability entity) {
    return LiabilityModel(
      id: entity.id,
      name: entity.name,
      typeIndex: entity.type.index,
      initialBalance: entity.initialBalance,
      creditLimit: entity.creditLimit,
      interestRate: entity.interestRate,
      createdAt: DateTime.now(),
    );
  }

  Liability toEntity(double currentBalance) {
    return Liability(
      id: id,
      name: name,
      type: LiabilityType.values[typeIndex],
      initialBalance: initialBalance,
      creditLimit: creditLimit,
      interestRate: interestRate,
      currentBalance: currentBalance,
    );
  }

  factory LiabilityModel.fromJson(Map<String, dynamic> json) =>
      _$LiabilityModelFromJson(json);

  Map<String, dynamic> toJson() => _$LiabilityModelToJson(this);
}
