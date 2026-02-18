// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'entity_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class EntityTypeAdapter extends TypeAdapter<EntityType> {
  @override
  final typeId = 20;

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
