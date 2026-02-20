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
      entityId: fields[9] as String,
      entityType: fields[1] as EntityType,
      opType: fields[2] as OpType,
      payloadJson: fields[3] as String,
      createdAt: fields[4] as DateTime,
      retryCount: fields[5] == null ? 0 : (fields[5] as num).toInt(),
      status: fields[6] == null
          ? OutboxStatus.pending
          : fields[6] as OutboxStatus,
      lastError: fields[7] as String?,
      nextRetryAt: fields[8] as DateTime?,
    );
  }

  @override
  void write(BinaryWriter writer, OutboxItem obj) {
    writer
      ..writeByte(10)
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
      ..write(obj.nextRetryAt)
      ..writeByte(9)
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

class OutboxStatusAdapter extends TypeAdapter<OutboxStatus> {
  @override
  final typeId = 20;

  @override
  OutboxStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return OutboxStatus.pending;
      case 1:
        return OutboxStatus.sent;
      case 2:
        return OutboxStatus.failed;
      default:
        return OutboxStatus.pending;
    }
  }

  @override
  void write(BinaryWriter writer, OutboxStatus obj) {
    switch (obj) {
      case OutboxStatus.pending:
        writer.writeByte(0);
      case OutboxStatus.sent:
        writer.writeByte(1);
      case OutboxStatus.failed:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OutboxStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class OpTypeAdapter extends TypeAdapter<OpType> {
  @override
  final typeId = 21;

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

class EntityTypeAdapter extends TypeAdapter<EntityType> {
  @override
  final typeId = 22;

  @override
  EntityType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return EntityType.group;
      case 1:
        return EntityType.groupMember;
      case 2:
        return EntityType.groupExpense;
      case 3:
        return EntityType.settlement;
      case 4:
        return EntityType.invite;
      case 5:
        return EntityType.expense;
      case 6:
        return EntityType.income;
      case 7:
        return EntityType.category;
      case 8:
        return EntityType.budget;
      case 9:
        return EntityType.goal;
      case 10:
        return EntityType.contribution;
      case 11:
        return EntityType.recurringRule;
      default:
        return EntityType.group;
    }
  }

  @override
  void write(BinaryWriter writer, EntityType obj) {
    switch (obj) {
      case EntityType.group:
        writer.writeByte(0);
      case EntityType.groupMember:
        writer.writeByte(1);
      case EntityType.groupExpense:
        writer.writeByte(2);
      case EntityType.settlement:
        writer.writeByte(3);
      case EntityType.invite:
        writer.writeByte(4);
      case EntityType.expense:
        writer.writeByte(5);
      case EntityType.income:
        writer.writeByte(6);
      case EntityType.category:
        writer.writeByte(7);
      case EntityType.budget:
        writer.writeByte(8);
      case EntityType.goal:
        writer.writeByte(9);
      case EntityType.contribution:
        writer.writeByte(10);
      case EntityType.recurringRule:
        writer.writeByte(11);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EntityTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
