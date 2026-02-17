// lib/features/budgets/data/models/budget_model.dart
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:hive_ce/hive.dart';

part 'budget_model.g.dart'; // Ensure this file is generated

@HiveType(typeId: 5) // New typeId
class BudgetModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final int budgetTypeIndex; // BudgetType enum index

  @HiveField(3)
  final double targetAmount;

  @HiveField(4)
  final int periodTypeIndex; // BudgetPeriodType enum index

  @HiveField(5)
  final DateTime? startDate; // Nullable for recurring

  @HiveField(6)
  final DateTime? endDate; // Nullable for recurring

  @HiveField(7)
  final List<String>? categoryIds; // Nullable for overall type

  @HiveField(8)
  final String? notes;

  @HiveField(9)
  final DateTime createdAt;

  BudgetModel({
    required this.id,
    required this.name,
    required this.budgetTypeIndex,
    required this.targetAmount,
    required this.periodTypeIndex,
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.notes,
    required this.createdAt,
  });

  factory BudgetModel.fromEntity(Budget entity) {
    return BudgetModel(
      id: entity.id,
      name: entity.name,
      budgetTypeIndex: entity.type.index,
      targetAmount: entity.targetAmount,
      periodTypeIndex: entity.period.index,
      startDate: entity.startDate,
      endDate: entity.endDate,
      categoryIds: entity.categoryIds,
      notes: entity.notes,
      createdAt: entity.createdAt,
    );
  }

  Budget toEntity() {
    return Budget(
      id: id,
      name: name,
      type: BudgetType.values[budgetTypeIndex],
      targetAmount: targetAmount,
      period: BudgetPeriodType.values[periodTypeIndex],
      startDate: startDate,
      endDate: endDate,
      categoryIds: categoryIds,
      notes: notes,
      createdAt: createdAt,
    );
  }
}
