// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'op_type.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

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
