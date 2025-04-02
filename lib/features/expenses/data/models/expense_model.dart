import 'package:hive/hive.dart';
import 'package:expense_tracker/features/expenses/domain/entities/expense.dart';
import 'package:expense_tracker/features/expenses/domain/entities/category.dart';
import 'package:json_annotation/json_annotation.dart'; // Import

part 'expense_model.g.dart'; // Ensure this is updated

@JsonSerializable() // Add Annotation
@HiveType(typeId: 0)
class ExpenseModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String categoryName;

  @HiveField(5)
  final String? subCategoryName;

  @HiveField(6)
  final String accountId;

  ExpenseModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryName,
    this.subCategoryName,
    required this.accountId,
  });

  factory ExpenseModel.fromEntity(Expense entity) {
    return ExpenseModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      categoryName: entity.category.name,
      subCategoryName: entity.category.subCategory,
      accountId: entity.accountId,
    );
  }

  Expense toEntity() {
    return Expense(
      id: id,
      title: title,
      amount: amount,
      date: date,
      category: Category(name: categoryName, subCategory: subCategoryName),
      accountId: accountId,
    );
  }

  // --- Add JsonSerializable methods ---
  factory ExpenseModel.fromJson(Map<String, dynamic> json) =>
      _$ExpenseModelFromJson(json);

  Map<String, dynamic> toJson() => _$ExpenseModelToJson(this);
  // ------------------------------------
}
