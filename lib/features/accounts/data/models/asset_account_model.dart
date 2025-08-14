import 'package:hive/hive.dart';
import 'package:expense_tracker/features/accounts/domain/entities/asset_account.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:expense_tracker/main.dart';

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
    final assetType = (typeIndex >= 0 && typeIndex < AssetType.values.length)
        ? AssetType.values[typeIndex]
        : AssetType.other;
    if (typeIndex < 0 || typeIndex >= AssetType.values.length) {
      log.warning(
        '[AssetAccountModel] Invalid typeIndex $typeIndex, defaulting to AssetType.other',
      );
    }
    return AssetAccount(
      id: id,
      name: name,
      type: assetType,
      initialBalance: initialBalance,
      currentBalance: currentBalance,
    );
  }

  factory AssetAccountModel.fromJson(Map<String, dynamic> json) =>
      _$AssetAccountModelFromJson(json);

  Map<String, dynamic> toJson() => _$AssetAccountModelToJson(this);
}
