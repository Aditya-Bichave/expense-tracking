// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final int typeId = 0;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      categoryId: fields[4] as String?,
      categorizationStatusValue: fields[5] as String,
      accountId: fields[6] as String,
      confidenceScoreValue: fields[7] as double?,
      isRecurring: fields[8] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
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
      ..write(obj.categorizationStatusValue)
      ..writeByte(6)
      ..write(obj.accountId)
      ..writeByte(7)
      ..write(obj.confidenceScoreValue)
      ..writeByte(8)
      ..write(obj.isRecurring);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ExpenseModel _$ExpenseModelFromJson(Map<String, dynamic> json) => ExpenseModel(
      id: json['id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      categoryId: json['categoryId'] as String?,
      categorizationStatusValue: json['categorizationStatusValue'] == null
          ? 'uncategorized'
          : ExpenseModel._categorizationStatusFromJson(
              json['categorizationStatusValue'] as String?),
      accountId: json['accountId'] as String,
      confidenceScoreValue: (json['confidenceScoreValue'] as num?)?.toDouble(),
      isRecurring: json['isRecurring'] as bool? ?? false,
    );

Map<String, dynamic> _$ExpenseModelToJson(ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      if (instance.categoryId case final value?) 'categoryId': value,
      'categorizationStatusValue': ExpenseModel._categorizationStatusToJson(
          instance.categorizationStatusValue),
      'accountId': instance.accountId,
      if (instance.confidenceScoreValue case final value?)
        'confidenceScoreValue': value,
      'isRecurring': instance.isRecurring,
    };
