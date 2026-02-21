import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';

void main() {
  group('BudgetType', () {
    test('displayName should return correct string', () {
      expect(BudgetType.overall.displayName, 'Overall Monthly');
      expect(BudgetType.categorySpecific.displayName, 'Category Specific');
    });
  });

  group('BudgetPeriodType', () {
    test('displayName should return correct string', () {
      expect(
        BudgetPeriodType.recurringMonthly.displayName,
        'Recurring Monthly',
      );
      expect(BudgetPeriodType.oneTime.displayName, 'One-Time Period');
    });
  });
}
