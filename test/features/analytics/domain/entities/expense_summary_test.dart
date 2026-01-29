import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';

void main() {
  group('ExpenseSummary', () {
    test('supports value equality', () {
      const summary1 = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: {'Food': 50.0, 'Transport': 50.0},
      );
      const summary2 = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: {'Food': 50.0, 'Transport': 50.0},
      );

      expect(summary1, equals(summary2));
    });

    test('props are correct', () {
      const summary = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: {'Food': 50.0},
      );

      expect(summary.props, [
        100.0,
        {'Food': 50.0},
      ]);
    });
  });
}
