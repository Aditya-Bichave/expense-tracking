import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:json_annotation/json_annotation.dart'; // Import

part 'asset_account_model.g.dart'; // Ensure this is updated

@JsonSerializable() // Add Annotation
@HiveType(typeId: 1)
class AssetAccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int typeIndex; // Store enum index

  @HiveField(3)
  final double initialBalance;

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
    IconData? icon;
    // switch (AssetType.values[typeIndex]) { ... set icon ... }

    return AssetAccount(
      id: id,
      name: name,
      type: AssetType.values[typeIndex],
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      iconData: icon,
    );
  }

  // --- Add JsonSerializable methods ---
  factory AssetAccountModel.fromJson(Map<String, dynamic> json) =>
      _$AssetAccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AssetAccountModelToJson(this);
  // ------------------------------------
}
