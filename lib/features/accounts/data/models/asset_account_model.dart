import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:json_annotation/json_annotation.dart';

part 'asset_account_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 1) // Keep existing typeId
class AssetAccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int typeIndex; // Store enum index

  @HiveField(3)
  final double initialBalance;

  // No longer storing icon data index
  // @HiveField(4) -> Removed

  AssetAccountModel({
    required this.id,
    required this.name,
    required this.typeIndex,
    required this.initialBalance,
  });

  factory AssetAccountModel.fromEntity(AssetAccount entity) {
    return AssetAccountModel(
      id: entity.id,
      name: entity.name,
      typeIndex: entity.type.index,
      initialBalance: entity.initialBalance,
    );
  }

  AssetAccount toEntity(double currentBalance) {
    // Icon is now determined in the entity or widget
    return AssetAccount(
      id: id,
      name: name,
      type: AssetType.values[typeIndex], // Get enum from index
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      // iconData is handled by the entity/widget now
    );
  }

  factory AssetAccountModel.fromJson(Map<String, dynamic> json) =>
      _$AssetAccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AssetAccountModelToJson(this);
}
