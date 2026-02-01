import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseSummary', () {
    test('supports value comparisons', () {
      const summary1 = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: {'Food': 50.0, 'Transport': 50.0},
      );
      const summary2 = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: {'Food': 50.0, 'Transport': 50.0},
      );

      expect(summary1, summary2);
    });

    test('props are correct', () {
      const summary = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: {'Food': 100.0},
      );

      expect(
        summary.props,
        [
          100.0,
          {'Food': 100.0}
        ],
      );
    });
  });
}
