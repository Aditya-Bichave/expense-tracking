// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GroupExpenseModelAdapter extends TypeAdapter<GroupExpenseModel> {
  @override
  final typeId = 11;

  @override
  GroupExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GroupExpenseModel(
      id: fields[0] as String,
      groupId: fields[1] as String,
      createdBy: fields[2] as String,
      title: fields[3] as String,
      amount: (fields[4] as num).toDouble(),
      currency: fields[5] as String,
      occurredAt: fields[6] as DateTime,
      notes: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GroupExpenseModel obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.groupId)
      ..writeByte(2)
      ..write(obj.createdBy)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.amount)
      ..writeByte(5)
      ..write(obj.currency)
      ..writeByte(6)
      ..write(obj.occurredAt)
      ..writeByte(7)
      ..write(obj.notes);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GroupExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GroupExpenseModel _$GroupExpenseModelFromJson(Map<String, dynamic> json) =>
    GroupExpenseModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      currency: json['currency'] as String,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$GroupExpenseModelToJson(GroupExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'group_id': instance.groupId,
      'created_by': instance.createdBy,
      'title': instance.title,
      'amount': instance.amount,
      'currency': instance.currency,
      'occurred_at': instance.occurredAt.toIso8601String(),
      'notes': instance.notes,
    };
