// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_member_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupMemberModelAdapter extends TypeAdapter<GroupMemberModel> {
  @override
  final typeId = 12;

  @override
  GroupMemberModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupMemberModel(
      id: fields[0] as String,
      groupId: fields[1] as String,
      userId: fields[2] as String,
      role: fields[3] as GroupRole,
      joinedAt: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GroupMemberModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.userId)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.joinedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupMemberModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupMemberModel _$GroupMemberModelFromJson(Map<String, dynamic> json) =>
    GroupMemberModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      userId: json['user_id'] as String,
      role: $enumDecode(_$GroupRoleEnumMap, json['role']),
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$GroupMemberModelToJson(GroupMemberModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'user_id': instance.userId,
      'role': _$GroupRoleEnumMap[instance.role]!,
      'joined_at': instance.joinedAt.toIso8601String(),
    };

const _$GroupRoleEnumMap = {
  GroupRole.admin: 'admin',
  GroupRole.member: 'member',
  GroupRole.viewer: 'viewer',
};
