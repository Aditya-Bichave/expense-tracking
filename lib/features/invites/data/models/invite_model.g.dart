// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'invite_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class InviteModelAdapter extends TypeAdapter<InviteModel> {
  @override
  final typeId = 16;

  @override
  InviteModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return InviteModel(
      id: fields[0] as String,
      groupId: fields[1] as String,
      token: fields[2] as String,
      expiresAt: fields[3] as DateTime,
      maxUses: (fields[4] as num).toInt(),
      usesCount: (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, InviteModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.token)
      ..writeByte(3)
      ..write(obj.expiresAt)
      ..writeByte(4)
      ..write(obj.maxUses)
      ..writeByte(5)
      ..write(obj.usesCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InviteModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InviteModel _$InviteModelFromJson(Map<String, dynamic> json) => InviteModel(
  id: json['id'] as String,
  groupId: json['group_id'] as String,
  token: json['token'] as String,
  expiresAt: DateTime.parse(json['expires_at'] as String),
  maxUses: (json['max_uses'] as num).toInt(),
  usesCount: (json['uses_count'] as num).toInt(),
);

Map<String, dynamic> _$InviteModelToJson(InviteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'token': instance.token,
      'expires_at': instance.expiresAt.toIso8601String(),
      'max_uses': instance.maxUses,
      'uses_count': instance.usesCount,
    };
