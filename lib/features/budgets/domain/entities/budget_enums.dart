// lib/features/budgets/domain/entities/budget_enums.dart
enum BudgetType { overall, categorySpecific }

enum BudgetPeriodType { recurringMonthly, oneTime }

extension BudgetTypeExtension on BudgetType {
  String get displayName {
    switch (this) {
      case BudgetType.overall:
        return 'Overall Monthly';
      case BudgetType.categorySpecific:
        return 'Category Specific';
    }
  }
}

extension BudgetPeriodTypeExtension on BudgetPeriodType {
  String get displayName {
    switch (this) {
      case BudgetPeriodType.recurringMonthly:
        return 'Recurring Monthly';
      case BudgetPeriodType.oneTime:
        return 'One-Time Period';
    }
  }
}
