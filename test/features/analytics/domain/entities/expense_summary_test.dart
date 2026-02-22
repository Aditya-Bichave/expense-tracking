import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';

void main() {
  test('ExpenseSummary supports equality', () {
    const s1 = ExpenseSummary(
      totalExpenses: 100,
      categoryBreakdown: {'Food': 100},
    );
    const s2 = ExpenseSummary(
      totalExpenses: 100,
      categoryBreakdown: {'Food': 100},
    );
    expect(s1, s2);
  });
}
