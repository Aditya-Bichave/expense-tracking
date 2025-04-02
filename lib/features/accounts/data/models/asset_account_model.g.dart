// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'asset_account_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AssetAccountModelAdapter extends TypeAdapter<AssetAccountModel> {
  @override
  final int typeId = 1;

  @override
  AssetAccountModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AssetAccountModel(
      id: fields[0] as String,
      name: fields[1] as String,
      typeIndex: fields[2] as int,
      initialBalance: fields[3] as double,
    );
  }

  @override
  void write(BinaryWriter writer, AssetAccountModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.typeIndex)
      ..writeByte(3)
      ..write(obj.initialBalance);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AssetAccountModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AssetAccountModel _$AssetAccountModelFromJson(Map<String, dynamic> json) =>
    AssetAccountModel(
      id: json['id'] as String,
      name: json['name'] as String,
      typeIndex: (json['typeIndex'] as num).toInt(),
      initialBalance: (json['initialBalance'] as num).toDouble(),
    );

Map<String, dynamic> _$AssetAccountModelToJson(AssetAccountModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'typeIndex': instance.typeIndex,
      'initialBalance': instance.initialBalance,
    };
