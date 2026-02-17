import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ComparisonValue', () {
    test('absoluteChange returns correct value', () {
      const val = ComparisonValue(currentValue: 100.0, previousValue: 50.0);
      expect(val.absoluteChange, 50.0);
    });

    test('absoluteChange returns null when previousValue is null', () {
      const val = ComparisonValue(currentValue: 100.0);
      expect(val.absoluteChange, isNull);
    });

    test('percentageChange returns correct value', () {
      const val = ComparisonValue(currentValue: 150.0, previousValue: 100.0);
      expect(val.percentageChange, 50.0);
    });

    test('percentageChange returns correct negative value', () {
      const val = ComparisonValue(currentValue: 50.0, previousValue: 100.0);
      expect(val.percentageChange, -50.0);
    });

    test('percentageChange handles 0 previous value (increase)', () {
      const val = ComparisonValue(currentValue: 100.0, previousValue: 0.0);
      expect(val.percentageChange, double.infinity);
    });

    test('percentageChange handles 0 previous value (decrease/negative)', () {
      const val = ComparisonValue(currentValue: -100.0, previousValue: 0.0);
      expect(val.percentageChange, double.negativeInfinity);
    });

    test('percentageChange handles 0 to 0', () {
      const val = ComparisonValue(currentValue: 0.0, previousValue: 0.0);
      expect(val.percentageChange, 0.0);
    });

    test('percentageChange returns null when previousValue is null', () {
      const val = ComparisonValue(currentValue: 100.0);
      expect(val.percentageChange, isNull);
    });
  });

  group('CategorySpendingData', () {
    test('currentTotalAmount getter works', () {
      const data = CategorySpendingData(
        categoryId: '1',
        categoryName: 'Test',
        categoryColor: Colors.red,
        totalAmount: ComparisonValue(currentValue: 100.0),
        percentage: 10.0,
      );
      expect(data.currentTotalAmount, 100.0);
    });
  });

  group('SpendingCategoryReportData', () {
    test('currentTotalSpending getter works', () {
      const data = SpendingCategoryReportData(
        totalSpending: ComparisonValue(currentValue: 500.0),
        spendingByCategory: [],
      );
      expect(data.currentTotalSpending, 500.0);
    });
  });

  group('TimeSeriesDataPoint', () {
    test('currentAmount getter works', () {
      final data = TimeSeriesDataPoint(
        date: DateTime(2023, 1, 1),
        amount: const ComparisonValue(currentValue: 200.0),
      );
      expect(data.currentAmount, 200.0);
    });
  });

  group('IncomeExpensePeriodData', () {
    final tStart = DateTime(2023, 1, 1);

    test('netFlow calculation works with comparison', () {
      final data = IncomeExpensePeriodData(
        periodStart: tStart,
        totalIncome: const ComparisonValue(
          currentValue: 1000.0,
          previousValue: 800.0,
        ),
        totalExpense: const ComparisonValue(
          currentValue: 600.0,
          previousValue: 500.0,
        ),
      );
      // Net Flow: Current = 1000 - 600 = 400. Previous = 800 - 500 = 300.
      expect(data.netFlow.currentValue, 400.0);
      expect(data.netFlow.previousValue, 300.0);
    });

    test('netFlow calculation works without comparison', () {
      final data = IncomeExpensePeriodData(
        periodStart: tStart,
        totalIncome: const ComparisonValue(currentValue: 1000.0),
        totalExpense: const ComparisonValue(currentValue: 600.0),
      );
      expect(data.netFlow.currentValue, 400.0);
      expect(data.netFlow.previousValue, isNull);
    });

    test('getters work', () {
      final data = IncomeExpensePeriodData(
        periodStart: tStart,
        totalIncome: const ComparisonValue(currentValue: 1000.0),
        totalExpense: const ComparisonValue(currentValue: 600.0),
      );
      expect(data.currentTotalIncome, 1000.0);
      expect(data.currentTotalExpense, 600.0);
      expect(data.currentNetFlow, 400.0);
    });
  });

  group('BudgetPerformanceData', () {
    final tBudget = Budget(
      id: '1',
      name: 'Test',
      type: BudgetType.overall,
      targetAmount: 100.0,
      period: BudgetPeriodType.recurringMonthly,
      createdAt: DateTime.now(),
    );

    test('getters work', () {
      final data = BudgetPerformanceData(
        budget: tBudget,
        actualSpending: const ComparisonValue(currentValue: 80.0),
        varianceAmount: const ComparisonValue(currentValue: 20.0),
        currentVariancePercent: 20.0,
        health: BudgetHealth.thriving,
        statusColor: Colors.green,
      );
      expect(data.currentActualSpending, 80.0);
      expect(data.currentVarianceAmount, 20.0);
    });

    test('varianceChangePercent returns correct value', () {
      final data = BudgetPerformanceData(
        budget: tBudget,
        actualSpending: const ComparisonValue(currentValue: 80.0),
        varianceAmount: const ComparisonValue(currentValue: 20.0),
        currentVariancePercent: 20.0,
        previousVariancePercent: 10.0,
        health: BudgetHealth.thriving,
        statusColor: Colors.green,
      );
      expect(data.varianceChangePercent, 10.0);
    });

    test('varianceChangePercent returns null if previous is null', () {
      final data = BudgetPerformanceData(
        budget: tBudget,
        actualSpending: const ComparisonValue(currentValue: 80.0),
        varianceAmount: const ComparisonValue(currentValue: 20.0),
        currentVariancePercent: 20.0,
        previousVariancePercent: null,
        health: BudgetHealth.thriving,
        statusColor: Colors.green,
      );
      expect(data.varianceChangePercent, isNull);
    });
  });
}
