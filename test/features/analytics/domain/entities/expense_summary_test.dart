import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseSummary', () {
    const double totalExpenses = 100.0;
    final Map<String, double> categoryBreakdown = {'Food': 60.0, 'Transport': 40.0};
    final expenseSummary = ExpenseSummary(
      totalExpenses: totalExpenses,
      categoryBreakdown: categoryBreakdown,
    );

    test('supports value equality', () {
      final expenseSummary2 = ExpenseSummary(
        totalExpenses: totalExpenses,
        categoryBreakdown: categoryBreakdown,
      );
      expect(expenseSummary, equals(expenseSummary2));
    });

    test('props are correct', () {
      expect(expenseSummary.props, [totalExpenses, categoryBreakdown]);
    });
  });
}
