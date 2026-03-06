// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dead_letter_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DeadLetterModelAdapter extends TypeAdapter<DeadLetterModel> {
  @override
  final typeId = 24;

  @override
  DeadLetterModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DeadLetterModel(
      id: fields[0] as String,
      table: fields[1] as String,
      operation: fields[2] as OpType,
      payload: (fields[3] as Map).cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      failedAt: fields[5] as DateTime,
      lastError: fields[6] as String,
      retryCount: (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, DeadLetterModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.table)
      ..writeByte(2)
      ..write(obj.operation)
      ..writeByte(3)
      ..write(obj.payload)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.failedAt)
      ..writeByte(6)
      ..write(obj.lastError)
      ..writeByte(7)
      ..write(obj.retryCount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeadLetterModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
