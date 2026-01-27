import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDownloaderService extends Mock implements DownloaderService {}

void main() {
  late CsvExportHelper helper;
  late MockDownloaderService mockDownloaderService;

  setUp(() {
    mockDownloaderService = MockDownloaderService();
    helper = CsvExportHelper(downloaderService: mockDownloaderService);
  });

  const currencySymbol = '\$';

  group('exportSpendingCategoryReport', () {
    test('should return CSV string', () async {
      final tData = SpendingCategoryReportData(
        totalSpending: const ComparisonValue(currentValue: 100),
        spendingByCategory: [
          CategorySpendingData(
            categoryId: '1',
            categoryName: 'Food',
            categoryColor: Colors.red,
            totalAmount: const ComparisonValue(currentValue: 100),
            percentage: 1.0,
          )
        ],
      );

      final result =
          await helper.exportSpendingCategoryReport(tData, currencySymbol);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv, contains('Category,Amount (\$),Percentage'));
        expect(csv, contains('Food,100.00,100.0%'));
        expect(csv, contains('TOTAL,100.00,100.0%'));
      }, (_) {});
    });
  });

  group('exportSpendingTimeReport', () {
    test('should return CSV string', () async {
      final tData = SpendingTimeReportData(
        spendingData: [
          TimeSeriesDataPoint(
            date: DateTime(2023, 1, 1),
            amount: const ComparisonValue(currentValue: 50),
          )
        ],
        granularity: TimeSeriesGranularity.daily,
      );

      final result =
          await helper.exportSpendingTimeReport(tData, currencySymbol);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv, contains('Period Start,Amount (\$)'));
        expect(csv, contains('2023-01-01,50.00'));
      }, (_) {});
    });
  });

  group('exportIncomeExpenseReport', () {
    test('should return CSV string', () async {
      final tData = IncomeExpenseReportData(
        periodData: [
          IncomeExpensePeriodData(
            periodStart: DateTime(2023, 1),
            totalIncome: const ComparisonValue(currentValue: 1000),
            totalExpense: const ComparisonValue(currentValue: 500),
          )
        ],
        periodType: IncomeExpensePeriodType.monthly,
      );

      final result =
          await helper.exportIncomeExpenseReport(tData, currencySymbol);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv,
            contains('Period Start,Income (\$),Expense (\$),Net Flow (\$)'));
        expect(csv, contains('2023-Jan,1000.00,500.00,500.00'));
      }, (_) {});
    });
  });

  group('exportBudgetPerformanceReport', () {
    test('should return CSV string', () async {
      final tData = BudgetPerformanceReportData(
        performanceData: [
          BudgetPerformanceData(
            budget: Budget(
              id: '1',
              name: 'Test Budget',
              type: BudgetType.overall,
              targetAmount: 1000,
              period: BudgetPeriodType.recurringMonthly,
              createdAt: DateTime.now(),
            ),
            actualSpending: const ComparisonValue(currentValue: 500),
            varianceAmount: const ComparisonValue(currentValue: 500),
            currentVariancePercent: 50.0,
            health: BudgetHealth.thriving,
            statusColor: Colors.green,
          )
        ],
      );

      final result =
          await helper.exportBudgetPerformanceReport(tData, currencySymbol);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(
            csv,
            contains(
                'Budget,Target (\$),Actual (\$),Variance (\$),Variance (%)'));
        expect(csv, contains('Test Budget,1000.00,500.00,500.00,50.0%'));
      }, (_) {});
    });
  });

  group('exportGoalProgressReport', () {
    test('should return CSV string', () async {
      final tData = GoalProgressReportData(
        progressData: [
          GoalProgressData(
            goal: Goal(
              id: '1',
              name: 'Test Goal',
              targetAmount: 1000,
              totalSaved: 500,
              status: GoalStatus.active,
              createdAt: DateTime.now(),
            ),
            contributions: const [],
          )
        ],
      );

      final result =
          await helper.exportGoalProgressReport(tData, currencySymbol);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(
            csv,
            contains(
                'Goal,Target (\$),Saved (\$),Remaining (\$),Progress (%),Target Date,Status,Est. Daily Save,Est. Monthly Save,Est. Completion'));
        expect(csv, contains('Test Goal,1000.00,500.00,500.00,50.0'));
      }, (_) {});
    });
  });
}
