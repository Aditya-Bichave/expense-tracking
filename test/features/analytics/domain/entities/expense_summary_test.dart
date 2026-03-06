import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const tExpenseSummary = ExpenseSummary(
    totalExpenses: 500,
    categoryBreakdown: {'Food': 200, 'Transport': 300},
  );

  test('should be a subclass of Equatable and return correct props', () {
    // assert
    expect(tExpenseSummary.totalExpenses, 500);
    expect(tExpenseSummary.categoryBreakdown, {'Food': 200, 'Transport': 300});
    expect(tExpenseSummary.props, [
      500,
      {'Food': 200, 'Transport': 300},
    ]);
  });

  test('should support value equality', () {
    const tExpenseSummary2 = ExpenseSummary(
      totalExpenses: 500,
      categoryBreakdown: {'Food': 200, 'Transport': 300},
    );

    expect(tExpenseSummary, equals(tExpenseSummary2));
  });
}
