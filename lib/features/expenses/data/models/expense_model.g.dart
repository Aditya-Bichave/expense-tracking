// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpenseModelAdapter extends TypeAdapter<ExpenseModel> {
  @override
  final typeId = 0;

  @override
  ExpenseModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseModel(
      id: fields[0] as String,
      title: fields[1] as String,
      amount: (fields[2] as num).toDouble(),
      date: fields[3] as DateTime,
      categoryId: fields[4] as String?,
      categorizationStatusValue: fields[5] == null
          ? 'uncategorized'
          : fields[5] as String,
      accountId: fields[6] as String,
      confidenceScoreValue: (fields[7] as num?)?.toDouble(),
      isRecurring: fields[8] == null ? false : fields[8] as bool,
      merchantId: fields[9] as String?,
      groupId: fields[10] as String?,
      createdBy: fields[11] as String?,
      currency: fields[12] == null ? 'USD' : fields[12] as String,
      notes: fields[13] as String?,
      receiptUrl: fields[14] as String?,
      clientGeneratedId: fields[15] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseModel obj) {
    writer
      ..writeByte(16)
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
      ..write(obj.isRecurring)
      ..writeByte(9)
      ..write(obj.merchantId)
      ..writeByte(10)
      ..write(obj.groupId)
      ..writeByte(11)
      ..write(obj.createdBy)
      ..writeByte(12)
      ..write(obj.currency)
      ..writeByte(13)
      ..write(obj.notes)
      ..writeByte(14)
      ..write(obj.receiptUrl)
      ..writeByte(15)
      ..write(obj.clientGeneratedId);
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
          json['categorizationStatusValue'] as String?,
        ),
  accountId: json['accountId'] as String,
  confidenceScoreValue: (json['confidenceScoreValue'] as num?)?.toDouble(),
  isRecurring: json['isRecurring'] as bool? ?? false,
  merchantId: json['merchantId'] as String?,
  groupId: json['groupId'] as String?,
  createdBy: json['createdBy'] as String?,
  currency: json['currency'] as String? ?? 'USD',
  notes: json['notes'] as String?,
  receiptUrl: json['receiptUrl'] as String?,
  clientGeneratedId: json['clientGeneratedId'] as String?,
);

Map<String, dynamic> _$ExpenseModelToJson(ExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'categoryId': ?instance.categoryId,
      'categorizationStatusValue': ExpenseModel._categorizationStatusToJson(
        instance.categorizationStatusValue,
      ),
      'accountId': instance.accountId,
      'confidenceScoreValue': ?instance.confidenceScoreValue,
      'isRecurring': instance.isRecurring,
      'merchantId': ?instance.merchantId,
      'groupId': ?instance.groupId,
      'createdBy': ?instance.createdBy,
      'currency': instance.currency,
      'notes': ?instance.notes,
      'receiptUrl': ?instance.receiptUrl,
      'clientGeneratedId': ?instance.clientGeneratedId,
    };
