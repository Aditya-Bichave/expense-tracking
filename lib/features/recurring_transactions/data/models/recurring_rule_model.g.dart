// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recurring_rule_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecurringRuleModelAdapter extends TypeAdapter<RecurringRuleModel> {
  @override
  final typeId = 10;

  @override
  RecurringRuleModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecurringRuleModel(
      id: fields[0] as String,
      userId: fields[1] as String?,
      amount: (fields[2] as num).toDouble(),
      description: fields[3] as String,
      categoryId: fields[4] as String,
      accountId: fields[5] as String,
      transactionTypeIndex: (fields[6] as num).toInt(),
      frequencyIndex: (fields[7] as num).toInt(),
      interval: (fields[8] as num).toInt(),
      startDate: fields[9] as DateTime,
      dayOfWeek: (fields[10] as num?)?.toInt(),
      dayOfMonth: (fields[11] as num?)?.toInt(),
      endConditionTypeIndex: (fields[12] as num).toInt(),
      endDate: fields[13] as DateTime?,
      totalOccurrences: (fields[14] as num?)?.toInt(),
      statusIndex: (fields[15] as num).toInt(),
      nextOccurrenceDate: fields[16] as DateTime,
      occurrencesGenerated: (fields[17] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, RecurringRuleModel obj) {
    writer
      ..writeByte(18)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.userId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.description)
      ..writeByte(4)
      ..write(obj.categoryId)
      ..writeByte(5)
      ..write(obj.accountId)
      ..writeByte(6)
      ..write(obj.transactionTypeIndex)
      ..writeByte(7)
      ..write(obj.frequencyIndex)
      ..writeByte(8)
      ..write(obj.interval)
      ..writeByte(9)
      ..write(obj.startDate)
      ..writeByte(10)
      ..write(obj.dayOfWeek)
      ..writeByte(11)
      ..write(obj.dayOfMonth)
      ..writeByte(12)
      ..write(obj.endConditionTypeIndex)
      ..writeByte(13)
      ..write(obj.endDate)
      ..writeByte(14)
      ..write(obj.totalOccurrences)
      ..writeByte(15)
      ..write(obj.statusIndex)
      ..writeByte(16)
      ..write(obj.nextOccurrenceDate)
      ..writeByte(17)
      ..write(obj.occurrencesGenerated);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurringRuleModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
