import 'package:hive/hive.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/entities/income_category.dart';

part 'income_model.g.dart'; // Generate this

@HiveType(typeId: 2) // Ensure unique typeId
class IncomeModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final double amount;

  @HiveField(3)
  final DateTime date;

  @HiveField(4)
  final String categoryName; // Store category name

  @HiveField(5)
  final String accountId;

  @HiveField(6)
  final String? notes;

  IncomeModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.categoryName,
    required this.accountId,
    this.notes,
  });

  factory IncomeModel.fromEntity(Income entity) {
    return IncomeModel(
      id: entity.id,
      title: entity.title,
      amount: entity.amount,
      date: entity.date,
      categoryName: entity.category.name, // Store name
      accountId: entity.accountId,
      notes: entity.notes,
    );
  }

  Income toEntity() {
    return Income(
      id: id,
      title: title,
      amount: amount,
      date: date,
      category:
          IncomeCategory(name: categoryName), // Recreate category from name
      accountId: accountId,
      notes: notes,
    );
  }
}
