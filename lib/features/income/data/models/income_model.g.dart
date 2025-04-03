// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'income_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class IncomeModelAdapter extends TypeAdapter<IncomeModel> {
  @override
  final int typeId = 2;

  @override
  IncomeModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return IncomeModel(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      categoryId: fields[4] as String?,
      categorizationStatusValue: fields[7] as String,
      accountId: fields[5] as String,
      notes: fields[6] as String?,
      confidenceScoreValue: fields[8] as double?,
    );
  }

  @override
  void write(BinaryWriter writer, IncomeModel obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.accountId)
      ..writeByte(6)
      ..write(obj.notes)
      ..writeByte(7)
      ..write(obj.categorizationStatusValue)
      ..writeByte(8)
      ..write(obj.confidenceScoreValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IncomeModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

IncomeModel _$IncomeModelFromJson(Map<String, dynamic> json) => IncomeModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      categoryId: json['categoryId'] as String?,
      categorizationStatusValue: json['categorizationStatusValue'] == null
          ? 'uncategorized'
          : IncomeModel._categorizationStatusFromJson(
              json['categorizationStatusValue'] as String?),
      accountId: json['accountId'] as String,
      notes: json['notes'] as String?,
      confidenceScoreValue: (json['confidenceScoreValue'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$IncomeModelToJson(IncomeModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      if (instance.categoryId case final value?) 'categoryId': value,
      'accountId': instance.accountId,
      'notes': instance.notes,
      'categorizationStatusValue': IncomeModel._categorizationStatusToJson(
          instance.categorizationStatusValue),
      if (instance.confidenceScoreValue case final value?)
        'confidenceScoreValue': value,
    };
