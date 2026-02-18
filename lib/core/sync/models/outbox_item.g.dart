// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'outbox_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class OutboxItemAdapter extends TypeAdapter<OutboxItem> {
  @override
  final typeId = 12;

  @override
  OutboxItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return OutboxItem(
      id: fields[0] as String,
      entityType: fields[1] as EntityType,
      opType: fields[2] as OpType,
      payloadJson: fields[3] as String,
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      status: fields[6] == null ? 'pending' : fields[6] as String,
      lastError: fields[7] as String?,
      entityId: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, OutboxItem obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.entityType)
      ..writeByte(2)
      ..write(obj.opType)
      ..writeByte(3)
      ..write(obj.payloadJson)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.lastError)
      ..writeByte(8)
      ..write(obj.entityId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutboxItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
