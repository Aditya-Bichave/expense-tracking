// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_role.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupRoleAdapter extends TypeAdapter<GroupRole> {
  @override
  final typeId = 22;

  @override
  GroupRole read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return GroupRole.admin;
      case 1:
        return GroupRole.member;
      case 2:
        return GroupRole.viewer;
      default:
        return GroupRole.admin;
    }
  }

  @override
  void write(BinaryWriter writer, GroupRole obj) {
    switch (obj) {
      case GroupRole.admin:
        writer.writeByte(0);
      case GroupRole.member:
        writer.writeByte(1);
      case GroupRole.viewer:
        writer.writeByte(2);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupRoleAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
