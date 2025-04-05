// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'goal_contribution_model.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GoalContributionModelAdapter extends TypeAdapter<GoalContributionModel> {
  @override
  final int typeId = 7;

  @override
  GoalContributionModel read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GoalContributionModel(
      id: fields[0] as String,
      goalId: fields[1] as String,
      amount: fields[2] as double,
      date: fields[3] as DateTime,
      note: fields[4] as String?,
      createdAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, GoalContributionModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.goalId)
      ..writeByte(2)
      ..write(obj.amount)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.note)
      ..writeByte(5)
      ..write(obj.createdAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalContributionModelAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
