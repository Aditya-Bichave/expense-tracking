// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_mutation_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SyncMutationModelAdapter extends TypeAdapter<SyncMutationModel> {
  @override
  final typeId = 12;

  @override
  SyncMutationModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SyncMutationModel(
      id: fields[0] as String,
      table: fields[1] as String,
      operation: fields[2] as OpType,
      payload: (fields[3] as Map).cast<String, dynamic>(),
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      status: fields[6] == null ? SyncStatus.pending : fields[6] as SyncStatus,
      lastError: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, SyncMutationModel obj) {
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
      ..write(obj.retryCount)
      ..writeByte(6)
      ..write(obj.status)
      ..writeByte(7)
      ..write(obj.lastError);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncMutationModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OpTypeAdapter extends TypeAdapter<OpType> {
  @override
  final typeId = 23;

  @override
  OpType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OpType.create;
      case 1:
        return OpType.update;
      case 2:
        return OpType.delete;
      default:
        return OpType.create;
    }
  }

  @override
  void write(BinaryWriter writer, OpType obj) {
    switch (obj) {
      case OpType.create:
        writer.writeByte(0);
      case OpType.update:
        writer.writeByte(1);
      case OpType.delete:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class SyncStatusAdapter extends TypeAdapter<SyncStatus> {
  @override
  final typeId = 22;

  @override
  SyncStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SyncStatus.pending;
      case 1:
        return SyncStatus.sent;
      case 2:
        return SyncStatus.failed;
      default:
        return SyncStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, SyncStatus obj) {
    switch (obj) {
      case SyncStatus.pending:
        writer.writeByte(0);
      case SyncStatus.sent:
        writer.writeByte(1);
      case SyncStatus.failed:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SyncStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
