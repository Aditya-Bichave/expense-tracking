// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_audit_log_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringRuleAuditLogModelAdapter
    extends TypeAdapter<RecurringRuleAuditLogModel> {
  @override
  final int typeId = 11;

  @override
  RecurringRuleAuditLogModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringRuleAuditLogModel(
      id: fields[0] as String,
      ruleId: fields[1] as String,
      timestamp: fields[2] as DateTime,
      userId: fields[3] as String,
      fieldChanged: fields[4] as String,
      oldValue: fields[5] as String,
      newValue: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, RecurringRuleAuditLogModel obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.ruleId)
      ..writeByte(2)
      ..write(obj.timestamp)
      ..writeByte(3)
      ..write(obj.userId)
      ..writeByte(4)
      ..write(obj.fieldChanged)
      ..writeByte(5)
      ..write(obj.oldValue)
      ..writeByte(6)
      ..write(obj.newValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleAuditLogModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
