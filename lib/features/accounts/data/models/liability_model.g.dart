// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'liability_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class LiabilityModelAdapter extends TypeAdapter<LiabilityModel> {
  @override
  final int typeId = 2;

  @override
  LiabilityModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return LiabilityModel(
      id: fields[0] as String,
      userId: fields[1] as String?,
      name: fields[2] as String,
      typeIndex: fields[3] as int,
      initialBalance: fields[4] as double,
      creditLimit: fields[5] as double?,
      interestRate: fields[6] as double?,
      createdAt: fields[7] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, LiabilityModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.name)
      ..writeByte(3)
      ..write(obj.typeIndex)
      ..writeByte(4)
      ..write(obj.initialBalance)
      ..writeByte(5)
      ..write(obj.creditLimit)
      ..writeByte(6)
      ..write(obj.interestRate)
      ..writeByte(7)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LiabilityModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LiabilityModel _$LiabilityModelFromJson(Map<String, dynamic> json) =>
    LiabilityModel(
      id: json['id'] as String,
      userId: json['userId'] as String?,
      name: json['name'] as String,
      typeIndex: (json['typeIndex'] as num).toInt(),
      initialBalance: (json['initialBalance'] as num).toDouble(),
      creditLimit: (json['creditLimit'] as num?)?.toDouble(),
      interestRate: (json['interestRate'] as num?)?.toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$LiabilityModelToJson(LiabilityModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'typeIndex': instance.typeIndex,
      'initialBalance': instance.initialBalance,
      'creditLimit': instance.creditLimit,
      'interestRate': instance.interestRate,
      'createdAt': instance.createdAt.toIso8601String(),
    };
