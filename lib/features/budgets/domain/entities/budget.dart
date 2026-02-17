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

  /// Returns the period start and end dates for the provided [reference] date.
  ///
  /// For [BudgetPeriodType.recurringMonthly] budgets, this calculates the first
  /// and last day of the month that contains [reference]. The last day includes
  /// the end-of-day time (23:59:59) so comparisons are inclusive.
  ///
  /// For one-time budgets the configured [startDate] and [endDate] are returned
  /// (also including the end-of-day time for the end date). If the dates are not
  /// set this falls back to an impossible range (1900) which effectively yields
  /// no results.
  (DateTime, DateTime) getPeriodDatesFor(DateTime reference) {
    if (period == BudgetPeriodType.recurringMonthly) {
      final firstDayOfMonth = DateTime(reference.year, reference.month, 1);
      final lastDayOfMonth = DateTime(
        reference.year,
        reference.month + 1,
        0,
        23,
        59,
        59,
      );
      return (firstDayOfMonth, lastDayOfMonth);
    } else {
      final effectiveStartDate =
          startDate ?? DateTime(1900); // Should not be null for one-time
      final effectiveEndDate = (endDate != null)
          ? DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59)
          : DateTime(1900);
      return (effectiveStartDate, effectiveEndDate);
    }
  }

  /// Convenience wrapper that returns the period for the current date.
  (DateTime, DateTime) getCurrentPeriodDates() =>
      getPeriodDatesFor(DateTime.now());

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
