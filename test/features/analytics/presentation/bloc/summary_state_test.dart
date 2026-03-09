import 'package:expense_tracker/features/analytics/presentation/bloc/summary_bloc.dart';
import 'package:expense_tracker/features/analytics/domain/entities/expense_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SummaryState', () {
    test('SummaryInitial supports value comparisons', () {
      expect(SummaryInitial(), equals(SummaryInitial()));
    });

    test('SummaryLoading supports value comparisons', () {
      expect(const SummaryLoading(), equals(const SummaryLoading()));
      expect(
        const SummaryLoading(isReloading: true),
        equals(const SummaryLoading(isReloading: true)),
      );
      expect(
        const SummaryLoading(),
        isNot(equals(const SummaryLoading(isReloading: true))),
      );
    });

    test('SummaryLoaded supports value comparisons', () {
      const summary1 = ExpenseSummary(
        totalExpenses: 100,
        categoryBreakdown: {},
      );
      const summary2 = ExpenseSummary(
        totalExpenses: 100,
        categoryBreakdown: {},
      );
      const summary3 = ExpenseSummary(
        totalExpenses: 200,
        categoryBreakdown: {},
      );

      expect(
        const SummaryLoaded(summary1),
        equals(const SummaryLoaded(summary2)),
      );
      expect(
        const SummaryLoaded(summary1),
        isNot(equals(const SummaryLoaded(summary3))),
      );
    });

    test('SummaryError supports value comparisons', () {
      expect(const SummaryError('error'), equals(const SummaryError('error')));
      expect(
        const SummaryError('error1'),
        isNot(equals(const SummaryError('error2'))),
      );
    });
  });
}
