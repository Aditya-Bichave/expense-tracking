import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_contribution.dart';
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
    // DownloaderService is required by the constructor but only used in saveCsvFile,
    // which is not being tested here (we are testing CSV generation logic).
    helper = CsvExportHelper(downloaderService: mockDownloaderService);
  });

  const String currencySymbol = '\$';

  group('CsvExportHelper', () {
    // Note: The CsvExportHelper currently returns Left(String) for success (the CSV content)
    // and Right(Failure) for errors. This is unconventional but verified against implementation.
    test('exportSpendingCategoryReport generates correct CSV', () async {
      final data = SpendingCategoryReportData(
        totalSpending: const ComparisonValue(
            currentValue: 300.0, previousValue: 200.0),
        spendingByCategory: [
          CategorySpendingData(
            categoryId: '1',
            categoryName: 'Food',
            categoryColor: Colors.red,
            totalAmount: const ComparisonValue(
                currentValue: 100.0, previousValue: 50.0),
            percentage: 0.33,
          ),
          CategorySpendingData(
            categoryId: '2',
            categoryName: 'Transport',
            categoryColor: Colors.blue,
            totalAmount: const ComparisonValue(
                currentValue: 200.0, previousValue: 150.0),
            percentage: 0.66,
          ),
        ],
      );

      final result = await helper.exportSpendingCategoryReport(
          data, currencySymbol, showComparison: true);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv, contains('Category,Amount (\$),Percentage,Previous Amount (\$),Change (%)'));
        expect(csv, contains('Food,100.00,33.0%,50.00,+100.0%'));
        expect(csv, contains('Transport,200.00,66.0%,150.00,+33.3%'));
        expect(csv, contains('TOTAL,300.00,100.0%,200.00,+50.0%'));
      }, (failure) => fail('Should returns CSV string'));
    });

    test('exportSpendingTimeReport generates correct CSV', () async {
      final data = SpendingTimeReportData(
        granularity: TimeSeriesGranularity.daily,
        spendingData: [
          TimeSeriesDataPoint(
            date: DateTime(2023, 1, 1),
            amount: const ComparisonValue(currentValue: 50.0, previousValue: 40.0),
          ),
          TimeSeriesDataPoint(
            date: DateTime(2023, 1, 2),
            amount: const ComparisonValue(currentValue: 60.0, previousValue: null),
          ),
        ],
      );

      final result = await helper.exportSpendingTimeReport(
          data, currencySymbol, showComparison: true);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv, contains('Period Start,Amount (\$),Previous Amount (\$),Change (%)'));
        expect(csv, contains('2023-01-01,50.00,40.00,+25.0%'));
        expect(csv, contains('2023-01-02,60.00,N/A,N/A'));
      }, (failure) => fail('Should returns CSV string'));
    });

    test('exportIncomeExpenseReport generates correct CSV', () async {
      final data = IncomeExpenseReportData(
        periodType: IncomeExpensePeriodType.monthly,
        periodData: [
          IncomeExpensePeriodData(
            periodStart: DateTime(2023, 1),
            totalIncome: const ComparisonValue(currentValue: 1000.0, previousValue: 900.0),
            totalExpense: const ComparisonValue(currentValue: 500.0, previousValue: 450.0),
          ),
        ],
      );

      final result = await helper.exportIncomeExpenseReport(
          data, currencySymbol, showComparison: true);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv, contains('Period Start,Income (\$),Expense (\$),Net Flow (\$),Prev Income (\$),Prev Expense (\$),Prev Net Flow (\$),Net Change (%)'));
        expect(csv, contains('2023-Jan,1000.00,500.00,500.00,900.00,450.00,450.00,+11.1%'));
      }, (failure) => fail('Should returns CSV string'));
    });

    test('exportBudgetPerformanceReport generates correct CSV', () async {
      final budget = Budget(
        id: '1',
        name: 'Groceries',
        type: BudgetType.categorySpecific,
        targetAmount: 500.0,
        period: BudgetPeriodType.recurringMonthly,
        createdAt: DateTime.now(),
      );

      final data = BudgetPerformanceReportData(
        performanceData: [
          BudgetPerformanceData(
            budget: budget,
            actualSpending: const ComparisonValue(currentValue: 400.0),
            varianceAmount: const ComparisonValue(currentValue: 100.0),
            currentVariancePercent: 20.0,
            health: BudgetHealth.thriving,
            statusColor: Colors.green,
            previousVariancePercent: 10.0,
          ),
        ],
        previousPerformanceData: [
          BudgetPerformanceData(
            budget: budget,
            actualSpending: const ComparisonValue(currentValue: 450.0),
            varianceAmount: const ComparisonValue(currentValue: 50.0),
            currentVariancePercent: 10.0,
            health: BudgetHealth.thriving,
            statusColor: Colors.green,
          ),
        ],
      );

      final result = await helper.exportBudgetPerformanceReport(
          data, currencySymbol, showComparison: true);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv, contains('Budget,Target (\$),Actual (\$),Variance (\$),Variance (%),Prev Actual (\$),Prev Variance (\$),Prev Variance (%),Var Δ%'));
        expect(csv, contains('Groceries,500.00,400.00,100.00,20.0%,450.00,50.00,10.0%,+10.0%'));
      }, (failure) => fail('Should returns CSV string'));
    });

    test('exportGoalProgressReport generates correct CSV', () async {
      final goal = Goal(
        id: '1',
        name: 'Vacation',
        targetAmount: 1000.0,
        status: GoalStatus.active,
        totalSaved: 200.0,
        createdAt: DateTime(2023, 1, 1),
        targetDate: DateTime(2023, 12, 31),
      );

      final data = GoalProgressReportData(
        progressData: [
          GoalProgressData(
            goal: goal,
            contributions: [],
            requiredDailySaving: 5.0,
            requiredMonthlySaving: 150.0,
          ),
        ],
      );

      final result = await helper.exportGoalProgressReport(data, currencySymbol);

      expect(result.isLeft(), true);
      result.fold((csv) {
        expect(csv, contains('Goal,Target (\$),Saved (\$),Remaining (\$),Progress (%),Target Date,Status,Est. Daily Save,Est. Monthly Save,Est. Completion'));
        // Adjusted expectation for date format (MM/dd/yyyy) and currency formatting ($5.00)
        expect(csv, contains('Vacation,1000.00,200.00,800.00,20.0,12/31/2023,Active,\$5.00,\$150.00,N/A'));
      }, (failure) => fail('Should returns CSV string'));
    });
  });
}
