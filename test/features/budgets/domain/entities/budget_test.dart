import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Budget.getPeriodDatesFor', () {
    test('returns start and end of reference month for recurring budgets', () {
      final budget = Budget(
        id: '1',
        name: 'Test',
        type: BudgetType.overall,
        targetAmount: 100,
        period: BudgetPeriodType.recurringMonthly,
        createdAt: DateTime(2024, 1, 1),
      );
      final (start, end) = budget.getPeriodDatesFor(DateTime(2024, 3, 15));
      expect(start, DateTime(2024, 3, 1));
      expect(end, DateTime(2024, 4, 0, 23, 59, 59));
    });

    test('returns configured dates for one-time budgets', () {
      final budget = Budget(
        id: '2',
        name: 'OneTime',
        type: BudgetType.overall,
        targetAmount: 50,
        period: BudgetPeriodType.oneTime,
        startDate: DateTime(2024, 2, 10),
        endDate: DateTime(2024, 2, 20),
        createdAt: DateTime(2024, 1, 1),
      );
      final (start, end) = budget.getPeriodDatesFor(DateTime(2024, 5, 1));
      expect(start, DateTime(2024, 2, 10));
      expect(end, DateTime(2024, 2, 20, 23, 59, 59));
    });
  });
}
