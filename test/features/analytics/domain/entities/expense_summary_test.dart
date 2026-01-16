import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';

void main() {
  group('ExpenseSummary', () {
    test('supports value comparisons', () {
      final summary1 = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: const {'Food': 50.0, 'Transport': 50.0},
      );
      final summary2 = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: const {'Food': 50.0, 'Transport': 50.0},
      );

      expect(summary1, equals(summary2));
    });

    test('props are correct', () {
      final summary = ExpenseSummary(
        totalExpenses: 100.0,
        categoryBreakdown: const {'Food': 50.0},
      );

      expect(summary.props, [
        100.0,
        {'Food': 50.0}
      ]);
    });
  });
}
