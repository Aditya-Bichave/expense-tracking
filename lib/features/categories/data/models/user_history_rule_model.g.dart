// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_history_rule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserHistoryRuleModelAdapter extends TypeAdapter<UserHistoryRuleModel> {
  @override
  final int typeId = 4;

  @override
  UserHistoryRuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserHistoryRuleModel(
      ruleId: fields[0] as String,
      ruleType: fields[1] as String,
      matcher: fields[2] as String,
      assignedCategoryId: fields[3] as String,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, UserHistoryRuleModel obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.ruleId)
      ..writeByte(1)
      ..write(obj.ruleType)
      ..writeByte(2)
      ..write(obj.matcher)
      ..writeByte(3)
      ..write(obj.assignedCategoryId)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserHistoryRuleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
