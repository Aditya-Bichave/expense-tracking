// lib/features/budgets/domain/entities/budget.dart
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';

class Budget extends Equatable {
  final String id;
  final String name;
  final BudgetType type;
  final double targetAmount;
  final BudgetPeriodType period;
  final DateTime? startDate; // Required if period is oneTime
  final DateTime? endDate; // Required if period is oneTime
  final List<String>? categoryIds; // Required if type is categorySpecific
  final String? notes;
  final DateTime createdAt;

  const Budget({
    required this.id,
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.period,
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.notes,
    required this.createdAt,
  });

  // Helper to get current period start/end for calculations
  (DateTime, DateTime) getCurrentPeriodDates() {
    final now = DateTime.now();
    if (period == BudgetPeriodType.recurringMonthly) {
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final lastDayOfMonth =
          DateTime(now.year, now.month + 1, 0, 23, 59, 59); // End of day
      return (firstDayOfMonth, lastDayOfMonth);
    } else {
      // For one-time, return the defined dates or default to impossible range if null
      final effectiveStartDate =
          startDate ?? DateTime(1900); // Should not be null for one-time
      // Ensure endDate includes the full day
      final effectiveEndDate = (endDate != null)
          ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59)
          : DateTime(1900); // Should not be null for one-time
      return (effectiveStartDate, effectiveEndDate);
    }
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        targetAmount,
        period,
        startDate,
        endDate,
        categoryIds,
        notes,
        createdAt,
      ];

  Budget copyWith({
    String? id,
    String? name,
    BudgetType? type,
    double? targetAmount,
    BudgetPeriodType? period,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categoryIds,
    String? notes,
    DateTime? createdAt,
    bool clearNotes = false,
    bool clearCategoryIds = false,
    bool clearDates = false,
  }) {
    return Budget(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetAmount: targetAmount ?? this.targetAmount,
      period: period ?? this.period,
      startDate: clearDates ? null : (startDate ?? this.startDate),
      endDate: clearDates ? null : (endDate ?? this.endDate),
      categoryIds: clearCategoryIds ? null : (categoryIds ?? this.categoryIds),
      notes: clearNotes ? null : (notes ?? this.notes),
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
