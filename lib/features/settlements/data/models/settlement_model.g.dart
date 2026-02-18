// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settlement_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SettlementModelAdapter extends TypeAdapter<SettlementModel> {
  @override
  final typeId = 17;

  @override
  SettlementModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SettlementModel(
      id: fields[0] as String,
      groupId: fields[1] as String,
      fromUserId: fields[2] as String,
      toUserId: fields[3] as String,
      amount: (fields[4] as num).toDouble(),
      currency: fields[5] as String,
      createdAt: fields[6] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, SettlementModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.fromUserId)
      ..writeByte(3)
      ..write(obj.toUserId)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SettlementModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettlementModel _$SettlementModelFromJson(Map<String, dynamic> json) =>
    SettlementModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      fromUserId: json['from_user_id'] as String,
      toUserId: json['to_user_id'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$SettlementModelToJson(SettlementModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'from_user_id': instance.fromUserId,
      'to_user_id': instance.toUserId,
      'amount': instance.amount,
      'currency': instance.currency,
      'created_at': instance.createdAt.toIso8601String(),
    };
