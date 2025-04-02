import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';

part 'asset_account_model.g.dart'; // Generate this

@HiveType(typeId: 1) // Ensure unique typeId (ExpenseModel was 0)
class AssetAccountModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int typeIndex; // Store enum index

  @HiveField(3)
  final double initialBalance;

  // Note: currentBalance is NOT stored, it's calculated.
  // Note: iconData is NOT stored, it's mapped in the repository/entity if needed.

  AssetAccountModel({
    required this.id,
    required this.name,
    required this.typeIndex,
    required this.initialBalance,
  });

  // Mapper from Entity to Model (excluding calculated/UI fields)
  factory AssetAccountModel.fromEntity(AssetAccount entity) {
    return AssetAccountModel(
      id: entity.id,
      name: entity.name,
      typeIndex: entity.type.index, // Store enum index
      initialBalance: entity.initialBalance,
    );
  }

  // Mapper from Model to Entity (requires calculated balance)
  // This conversion will happen in the Repository where balance can be calculated.
  AssetAccount toEntity(double currentBalance) {
    // Map icon based on type if desired
    IconData? icon;
    // switch (AssetType.values[typeIndex]) { ... set icon ... }

    return AssetAccount(
      id: id,
      name: name,
      type: AssetType.values[typeIndex], // Get enum from index
      initialBalance: initialBalance,
      currentBalance: currentBalance, // Passed in after calculation
      iconData: icon,
    );
  }
}
