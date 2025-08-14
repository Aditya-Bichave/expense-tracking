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

  @HiveField(4)
  final String colorHex;

  AssetAccountModel({
    required this.id,
    required this.name,
    required this.typeIndex,
    required this.initialBalance,
    required this.colorHex,
  });

  factory AssetAccountModel.fromEntity(AssetAccount entity) {
    return AssetAccountModel(
      id: entity.id,
      name: entity.name,
      typeIndex: entity.type.index,
      initialBalance: entity.initialBalance,
      colorHex: entity.colorHex,
    );
  }

  AssetAccount toEntity(double currentBalance) {
    return AssetAccount(
      id: id,
      name: name,
      type: AssetType.values[typeIndex],
      initialBalance: initialBalance,
      currentBalance: currentBalance,
      colorHex: colorHex,
    );
  }

  factory AssetAccountModel.fromJson(Map<String, dynamic> json) =>
      _$AssetAccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AssetAccountModelToJson(this);
}
