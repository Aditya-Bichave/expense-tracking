import 'package:hive/hive.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';

part 'transaction_model.g.dart';

@JsonSerializable()
@HiveType(typeId: 3)
class TransactionModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final int typeIndex;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String? fromAccountId;

  @HiveField(5)
  final String? toAccountId;

  @HiveField(6)
  final String title;

  TransactionModel({
    required this.id,
    required this.typeIndex,
    required this.amount,
    required this.date,
    this.fromAccountId,
    this.toAccountId,
    required this.title,
  });

  factory TransactionModel.fromEntity(Transaction entity) {
    return TransactionModel(
      id: entity.id,
      title: entity.title,
      typeIndex: entity.type.index,
      amount: entity.amount,
      date: entity.date,
      fromAccountId: entity.fromAccountId,
      toAccountId: entity.toAccountId,
    );
  }

  Transaction toEntity() {
    return Transaction(
      id: id,
      title: title,
      type: TransactionType.values[typeIndex],
      amount: amount,
      date: date,
      fromAccountId: fromAccountId,
      toAccountId: toAccountId,
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      _$TransactionModelFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionModelToJson(this);
}
