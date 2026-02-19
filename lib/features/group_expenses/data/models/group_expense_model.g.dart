// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'group_expense_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExpensePayerModelAdapter extends TypeAdapter<ExpensePayerModel> {
  @override
  final typeId = 17;

  @override
  ExpensePayerModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpensePayerModel(
      userId: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
    );
  }

  @override
  void write(BinaryWriter writer, ExpensePayerModel obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.amount);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpensePayerModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExpenseSplitModelAdapter extends TypeAdapter<ExpenseSplitModel> {
  @override
  final typeId = 18;

  @override
  ExpenseSplitModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return ExpenseSplitModel(
      userId: fields[0] as String,
      amount: (fields[1] as num).toDouble(),
      splitTypeValue: fields[2] as String,
    );
  }

  @override
  void write(BinaryWriter writer, ExpenseSplitModel obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.userId)
      ..writeByte(1)
      ..write(obj.amount)
      ..writeByte(2)
      ..write(obj.splitTypeValue);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExpenseSplitModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class GroupExpenseModelAdapter extends TypeAdapter<GroupExpenseModel> {
  @override
  final typeId = 15;

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
      createdAt: fields[7] as DateTime,
      updatedAt: fields[8] as DateTime,
      payers: fields[9] == null
          ? const []
          : (fields[9] as List).cast<ExpensePayerModel>(),
      splits: fields[10] == null
          ? const []
          : (fields[10] as List).cast<ExpenseSplitModel>(),
    );
  }

  @override
  void write(BinaryWriter writer, GroupExpenseModel obj) {
    writer
      ..writeByte(11)
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
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.updatedAt)
      ..writeByte(9)
      ..write(obj.payers)
      ..writeByte(10)
      ..write(obj.splits);
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

ExpensePayerModel _$ExpensePayerModelFromJson(Map<String, dynamic> json) =>
    ExpensePayerModel(
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$ExpensePayerModelToJson(ExpensePayerModel instance) =>
    <String, dynamic>{'userId': instance.userId, 'amount': instance.amount};

ExpenseSplitModel _$ExpenseSplitModelFromJson(Map<String, dynamic> json) =>
    ExpenseSplitModel(
      userId: json['userId'] as String,
      amount: (json['amount'] as num).toDouble(),
      splitTypeValue: json['splitTypeValue'] as String,
    );

Map<String, dynamic> _$ExpenseSplitModelToJson(ExpenseSplitModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'amount': instance.amount,
      'splitTypeValue': instance.splitTypeValue,
    };

GroupExpenseModel _$GroupExpenseModelFromJson(
  Map<String, dynamic> json,
) => GroupExpenseModel(
  id: json['id'] as String,
  groupId: json['groupId'] as String,
  createdBy: json['createdBy'] as String,
  title: json['title'] as String,
  amount: (json['amount'] as num).toDouble(),
  currency: json['currency'] as String,
  occurredAt: DateTime.parse(json['occurredAt'] as String),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
  payers:
      (json['payers'] as List<dynamic>?)
          ?.map((e) => ExpensePayerModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  splits:
      (json['splits'] as List<dynamic>?)
          ?.map((e) => ExpenseSplitModel.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$GroupExpenseModelToJson(GroupExpenseModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'groupId': instance.groupId,
      'createdBy': instance.createdBy,
      'title': instance.title,
      'amount': instance.amount,
      'currency': instance.currency,
      'occurredAt': instance.occurredAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'payers': instance.payers,
      'splits': instance.splits,
    };
