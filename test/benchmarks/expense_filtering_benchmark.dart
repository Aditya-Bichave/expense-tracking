// ignore_for_file: avoid_print
import 'package:expense_tracker/features/expenses/data/models/expense_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Benchmark: Expense Filtering Performance', () {
    const int itemCount = 100000;
    print('Generating $itemCount expenses...');

    // Generate a large list of expenses
    final expenses = List.generate(itemCount, (index) {
      return ExpenseModel(
        id: 'expense_$index',
        title: 'Expense $index',
        amount: 10.0,
        date: DateTime.now(),
        categoryId: 'category_${index % 10}', // Cycles 0-9
        accountId: 'account_${index % 5}', // Cycles 0-4
      );
    });

    final accountFilter =
        'account_1,account_2,account_3'; // Filter for 3 out of 5 accounts

    print('Starting Benchmark 1: Unoptimized (Split inside loop)...');
    final stopwatchUnoptimized = Stopwatch()..start();

    // Unoptimized implementation: Split inside the loop
    final unoptimizedResults = expenses.where((expense) {
      if (accountFilter.isNotEmpty) {
        final ids = accountFilter.split(
          ',',
        ); // INEFFICIENT: Splitting string every iteration
        if (!ids.contains(expense.accountId)) return false;
      }
      return true;
    }).toList();

    stopwatchUnoptimized.stop();
    print('Unoptimized time: ${stopwatchUnoptimized.elapsedMilliseconds}ms');
    print('Unoptimized count: ${unoptimizedResults.length}');

    print('Starting Benchmark 2: Optimized (Split outside loop + Set)...');
    final stopwatchOptimized = Stopwatch()..start();

    // Optimized implementation: Split once outside, use Set for O(1) lookup
    final accountIdSet = accountFilter.isNotEmpty
        ? accountFilter.split(',').toSet()
        : null;

    final optimizedResults = expenses.where((expense) {
      if (accountIdSet != null && !accountIdSet.contains(expense.accountId)) {
        return false;
      }
      return true;
    }).toList();

    stopwatchOptimized.stop();
    print('Optimized time:   ${stopwatchOptimized.elapsedMilliseconds}ms');
    print('Optimized count:   ${optimizedResults.length}');

    // Verification
    expect(
      unoptimizedResults.length,
      optimizedResults.length,
      reason: 'Both methods should return the same number of results',
    );

    // The optimized version should be significantly faster.
    // We expect at least 2x improvement, but likely much more.
    final improvement =
        stopwatchUnoptimized.elapsedMilliseconds /
        stopwatchOptimized.elapsedMilliseconds;
    print('Speedup Factor: ${improvement.toStringAsFixed(2)}x');

    expect(
      stopwatchOptimized.elapsedMilliseconds,
      lessThan(stopwatchUnoptimized.elapsedMilliseconds),
      reason: 'Optimized method should be faster',
    );
  });
}
