import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';

void main() {
  group('ExpenseSummary', () {
    test('supports equality with same values', () {
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

    test('supports inequality with different total', () {
      const s1 = ExpenseSummary(
        totalExpenses: 100,
        categoryBreakdown: {'Food': 100},
      );
      const s2 = ExpenseSummary(
        totalExpenses: 200,
        categoryBreakdown: {'Food': 100},
      );
      expect(s1, isNot(equals(s2)));
    });

    test('supports inequality with different breakdown', () {
      const s1 = ExpenseSummary(
        totalExpenses: 100,
        categoryBreakdown: {'Food': 100},
      );
      const s2 = ExpenseSummary(
        totalExpenses: 100,
        categoryBreakdown: {'Transport': 100},
      );
      expect(s1, isNot(equals(s2)));
    });

    test('stores totalExpenses correctly', () {
      const summary = ExpenseSummary(
        totalExpenses: 250.50,
        categoryBreakdown: {},
      );
      expect(summary.totalExpenses, 250.50);
    });

    test('stores categoryBreakdown correctly', () {
      const breakdown = {
        'Food': 100.0,
        'Transport': 50.0,
        'Entertainment': 30.0,
      };
      const summary = ExpenseSummary(
        totalExpenses: 180,
        categoryBreakdown: breakdown,
      );
      expect(summary.categoryBreakdown, breakdown);
    });

    test('can have zero total expenses', () {
      const summary = ExpenseSummary(
        totalExpenses: 0,
        categoryBreakdown: {},
      );
      expect(summary.totalExpenses, 0);
    });

    test('can have empty category breakdown', () {
      const summary = ExpenseSummary(
        totalExpenses: 0,
        categoryBreakdown: {},
      );
      expect(summary.categoryBreakdown, isEmpty);
    });

    test('can have multiple categories in breakdown', () {
      const summary = ExpenseSummary(
        totalExpenses: 300,
        categoryBreakdown: {
          'Food': 100,
          'Transport': 50,
          'Entertainment': 75,
          'Shopping': 75,
        },
      );
      expect(summary.categoryBreakdown.length, 4);
      expect(summary.categoryBreakdown['Food'], 100);
      expect(summary.categoryBreakdown['Transport'], 50);
      expect(summary.categoryBreakdown['Entertainment'], 75);
      expect(summary.categoryBreakdown['Shopping'], 75);
    });

    test('props include both fields', () {
      const summary = ExpenseSummary(
        totalExpenses: 100,
        categoryBreakdown: {'Food': 100},
      );
      expect(summary.props, [100, {'Food': 100}]);
    });

    test('is const constructible', () {
      const summary = ExpenseSummary(
        totalExpenses: 100,
        categoryBreakdown: {'Food': 100},
      );
      expect(summary, isNotNull);
    });

    test('can handle large total amounts', () {
      const summary = ExpenseSummary(
        totalExpenses: 99999.99,
        categoryBreakdown: {'Major Purchase': 99999.99},
      );
      expect(summary.totalExpenses, 99999.99);
    });

    test('can handle decimal precision', () {
      const summary = ExpenseSummary(
        totalExpenses: 123.45,
        categoryBreakdown: {'Food': 123.45},
      );
      expect(summary.totalExpenses, 123.45);
      expect(summary.categoryBreakdown['Food'], 123.45);
    });
  });
}