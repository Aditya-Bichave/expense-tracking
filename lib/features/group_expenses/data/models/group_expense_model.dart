import 'package:expense_tracker/features/group_expenses/domain/entities/group_expense.dart';
import 'package:hive_ce/hive.dart';
import 'package:json_annotation/json_annotation.dart';

part 'group_expense_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 17)
class ExpensePayerModel {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final double amount;

  ExpensePayerModel({required this.userId, required this.amount});

  factory ExpensePayerModel.fromEntity(ExpensePayer entity) =>
      ExpensePayerModel(userId: entity.userId, amount: entity.amount);

  ExpensePayer toEntity() => ExpensePayer(userId: userId, amount: amount);

  factory ExpensePayerModel.fromJson(Map<String, dynamic> json) =>
      _$ExpensePayerModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExpensePayerModelToJson(this);
}

@JsonSerializable()
@HiveType(typeId: 18)
class ExpenseSplitModel {
  @HiveField(0)
  final String userId;
  @HiveField(1)
  final double amount;
  @HiveField(2)
  final String splitTypeValue;

  ExpenseSplitModel({
    required this.userId,
    required this.amount,
    required this.splitTypeValue,
  });

  factory ExpenseSplitModel.fromEntity(ExpenseSplit entity) =>
      ExpenseSplitModel(
        userId: entity.userId,
        amount: entity.amount,
        splitTypeValue: entity.splitType.value,
      );

  ExpenseSplit toEntity() => ExpenseSplit(
    userId: userId,
    amount: amount,
    splitType: SplitType.fromValue(splitTypeValue),
  );

  factory ExpenseSplitModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseSplitModelFromJson(json);
  Map<String, dynamic> toJson() => _$ExpenseSplitModelToJson(this);
}

@JsonSerializable(fieldRename: FieldRename.snake)
@HiveType(typeId: 15)
class GroupExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String groupId;
  @HiveField(2)
  final String createdBy;
  @HiveField(3)
  final String title;
  @HiveField(4)
  final double amount;
  @HiveField(5)
  final String currency;
  @HiveField(6)
  final DateTime occurredAt;
  @HiveField(7)
  final DateTime createdAt;
  @HiveField(8)
  final DateTime updatedAt;
  @HiveField(9)
  final List<ExpensePayerModel> payers;
  @HiveField(10)
  final List<ExpenseSplitModel> splits;

  GroupExpenseModel({
    required this.id,
    required this.groupId,
    required this.createdBy,
    required this.title,
    required this.amount,
    required this.currency,
    required this.occurredAt,
    required this.createdAt,
    required this.updatedAt,
    this.payers = const [],
    this.splits = const [],
  });

  factory GroupExpenseModel.fromEntity(GroupExpense entity) {
    return GroupExpenseModel(
      id: entity.id,
      groupId: entity.groupId,
      createdBy: entity.createdBy,
      title: entity.title,
      amount: entity.amount,
      currency: entity.currency,
      occurredAt: entity.occurredAt,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      payers: entity.payers
          .map((e) => ExpensePayerModel.fromEntity(e))
          .toList(),
      splits: entity.splits
          .map((e) => ExpenseSplitModel.fromEntity(e))
          .toList(),
    );
  }

  GroupExpense toEntity() {
    return GroupExpense(
      id: id,
      groupId: groupId,
      createdBy: createdBy,
      title: title,
      amount: amount,
      currency: currency,
      occurredAt: occurredAt,
      createdAt: createdAt,
      updatedAt: updatedAt,
      payers: payers.map((e) => e.toEntity()).toList(),
      splits: splits.map((e) => e.toEntity()).toList(),
    );
  }

  factory GroupExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$GroupExpenseModelFromJson(json);
  Map<String, dynamic> toJson() => _$GroupExpenseModelToJson(this);
}
