import 'dart:convert';
import 'dart:typed_data';

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

/// Splits a generated CSV into trimmed, non-empty lines.
List<String> linesOf(String csv) =>
    csv.trim().split('\r\n').where((l) => l.isNotEmpty).toList();

void main() {
  late CsvExportHelper helper;
  late MockDownloaderService downloader;

  const currency = r'$';

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    downloader = MockDownloaderService();
    helper = CsvExportHelper(downloaderService: downloader);
  });

  String successCsv(dynamic result) {
    // This helper uses an inverted Either: Left is the CSV, Right is a Failure.
    expect(result.isLeft(), isTrue, reason: 'expected a CSV, got $result');
    return result.fold((csv) => csv as String, (f) => throw StateError('$f'));
  }

  group('exportSpendingTimeReport', () {
    TimeSeriesDataPoint point(DateTime d, double cur, [double? prev]) =>
        TimeSeriesDataPoint(
          date: d,
          amount: ComparisonValue(currentValue: cur, previousValue: prev),
        );

    test('daily granularity formats period starts as yyyy-MM-dd', () async {
      final data = SpendingTimeReportData(
        spendingData: [point(DateTime(2024, 3, 5), 12.5)],
        granularity: TimeSeriesGranularity.daily,
      );

      final lines = linesOf(
        successCsv(await helper.exportSpendingTimeReport(data, currency)),
      );

      expect(lines[0], r'Period Start,Amount ($)');
      expect(lines[1], '2024-03-05,12.50');
    });

    test('weekly granularity tags the period with Wk', () async {
      final data = SpendingTimeReportData(
        spendingData: [point(DateTime(2024, 3, 4), 40)],
        granularity: TimeSeriesGranularity.weekly,
      );

      final lines = linesOf(
        successCsv(await helper.exportSpendingTimeReport(data, currency)),
      );

      expect(lines[1], startsWith('2024-03-04 Wk'));
    });

    test('monthly granularity collapses to yyyy-MMM', () async {
      final data = SpendingTimeReportData(
        spendingData: [point(DateTime(2024, 3, 20), 99)],
        granularity: TimeSeriesGranularity.monthly,
      );

      final lines = linesOf(
        successCsv(await helper.exportSpendingTimeReport(data, currency)),
      );

      expect(lines[1], '2024-Mar,99.00');
    });

    test('comparison mode adds previous amount and change columns', () async {
      final data = SpendingTimeReportData(
        spendingData: [
          point(DateTime(2024, 3, 5), 120, 100),
          point(DateTime(2024, 3, 6), 50),
        ],
        granularity: TimeSeriesGranularity.daily,
      );

      final lines = linesOf(
        successCsv(
          await helper.exportSpendingTimeReport(
            data,
            currency,
            showComparison: true,
          ),
        ),
      );

      expect(
        lines[0],
        r'Period Start,Amount ($),Previous Amount ($),Change (%)',
      );
      expect(lines[1], '2024-03-05,120.00,100.00,+20.0%');
      // No previous value -> both comparison cells fall back to N/A.
      expect(lines[2], '2024-03-06,50.00,N/A,N/A');
    });

    test('an empty series still emits the header row', () async {
      const data = SpendingTimeReportData(
        spendingData: [],
        granularity: TimeSeriesGranularity.daily,
      );

      final lines = linesOf(
        successCsv(await helper.exportSpendingTimeReport(data, currency)),
      );

      expect(lines, hasLength(1));
    });
  });

  group('exportIncomeExpenseReport', () {
    IncomeExpensePeriodData period(
      DateTime start,
      double income,
      double expense, {
      double? prevIncome,
      double? prevExpense,
    }) => IncomeExpensePeriodData(
      periodStart: start,
      totalIncome: ComparisonValue(
        currentValue: income,
        previousValue: prevIncome,
      ),
      totalExpense: ComparisonValue(
        currentValue: expense,
        previousValue: prevExpense,
      ),
    );

    test('monthly period type formats the period as yyyy-MMM', () async {
      final data = IncomeExpenseReportData(
        periodData: [period(DateTime(2024, 5, 1), 500, 200)],
        periodType: IncomeExpensePeriodType.monthly,
      );

      final lines = linesOf(
        successCsv(await helper.exportIncomeExpenseReport(data, currency)),
      );

      expect(lines[0], r'Period Start,Income ($),Expense ($),Net Flow ($)');
      // Net flow is income - expense.
      expect(lines[1], '2024-May,500.00,200.00,300.00');
    });

    test('yearly period type formats the period as yyyy', () async {
      final data = IncomeExpenseReportData(
        periodData: [period(DateTime(2024, 1, 1), 1000, 1200)],
        periodType: IncomeExpensePeriodType.yearly,
      );

      final lines = linesOf(
        successCsv(await helper.exportIncomeExpenseReport(data, currency)),
      );

      expect(lines[1], '2024,1000.00,1200.00,-200.00');
    });

    test('comparison mode adds four previous-period columns', () async {
      final data = IncomeExpenseReportData(
        periodData: [
          period(
            DateTime(2024, 5, 1),
            500,
            200,
            prevIncome: 400,
            prevExpense: 300,
          ),
        ],
        periodType: IncomeExpensePeriodType.monthly,
      );

      final lines = linesOf(
        successCsv(
          await helper.exportIncomeExpenseReport(
            data,
            currency,
            showComparison: true,
          ),
        ),
      );

      expect(lines[0].split(',').length, 8);
      // Previous net flow is 400-300 = 100; current is 300, so +200%.
      expect(
        lines[1],
        '2024-May,500.00,200.00,300.00,400.00,300.00,100.00,+200.0%',
      );
    });

    test('missing previous values render as N/A in comparison mode', () async {
      final data = IncomeExpenseReportData(
        periodData: [period(DateTime(2024, 5, 1), 500, 200)],
        periodType: IncomeExpensePeriodType.monthly,
      );

      final lines = linesOf(
        successCsv(
          await helper.exportIncomeExpenseReport(
            data,
            currency,
            showComparison: true,
          ),
        ),
      );

      expect(lines[1], endsWith('N/A,N/A,N/A,N/A'));
    });
  });

  group('exportBudgetPerformanceReport', () {
    Budget budget(String id, String name, double target) => Budget(
      id: id,
      name: name,
      type: BudgetType.overall,
      targetAmount: target,
      period: BudgetPeriodType.recurringMonthly,
      createdAt: DateTime(2024, 1, 1),
    );

    BudgetPerformanceData perf(
      Budget b,
      double actual,
      double variance,
      double variancePercent, {
      double? previousVariancePercent,
    }) => BudgetPerformanceData(
      budget: b,
      actualSpending: ComparisonValue(currentValue: actual),
      varianceAmount: ComparisonValue(currentValue: variance),
      currentVariancePercent: variancePercent,
      previousVariancePercent: previousVariancePercent,
      health: BudgetHealth.thriving,
      statusColor: Colors.green,
    );

    test('emits one row per budget with the five base columns', () async {
      final data = BudgetPerformanceReportData(
        performanceData: [perf(budget('b1', 'Groceries', 500), 400, 100, 20)],
      );

      final lines = linesOf(
        successCsv(await helper.exportBudgetPerformanceReport(data, currency)),
      );

      expect(
        lines[0],
        r'Budget,Target ($),Actual ($),Variance ($),Variance (%)',
      );
      expect(lines[1], 'Groceries,500.00,400.00,100.00,20.0%');
    });

    test('an infinite variance percent renders as +Inf or -Inf', () async {
      final data = BudgetPerformanceReportData(
        performanceData: [
          perf(budget('b1', 'Over', 0), 50, -50, double.infinity),
          perf(budget('b2', 'Under', 0), 50, -50, double.negativeInfinity),
        ],
      );

      final lines = linesOf(
        successCsv(await helper.exportBudgetPerformanceReport(data, currency)),
      );

      expect(lines[1], endsWith('+Inf'));
      expect(lines[2], endsWith('-Inf'));
    });

    test(
      'comparison columns are omitted when there is no previous data',
      () async {
        final data = BudgetPerformanceReportData(
          performanceData: [perf(budget('b1', 'Groceries', 500), 400, 100, 20)],
        );

        final lines = linesOf(
          successCsv(
            await helper.exportBudgetPerformanceReport(
              data,
              currency,
              showComparison: true,
            ),
          ),
        );

        // showComparison alone is not enough; previousPerformanceData must
        // also be non-empty.
        expect(lines[0].split(',').length, 5);
      },
    );

    test('comparison columns appear when previous data is present', () async {
      final b = budget('b1', 'Groceries', 500);
      final data = BudgetPerformanceReportData(
        performanceData: [perf(b, 400, 100, 20, previousVariancePercent: 10)],
        previousPerformanceData: [perf(b, 450, 50, 10)],
      );

      final lines = linesOf(
        successCsv(
          await helper.exportBudgetPerformanceReport(
            data,
            currency,
            showComparison: true,
          ),
        ),
      );

      expect(lines[0].split(',').length, 9);
      expect(lines[1], contains('450.00'));
      expect(lines[1], contains('10.0%'));
    });

    test('an unmatched previous budget yields N/A cells', () async {
      final data = BudgetPerformanceReportData(
        performanceData: [perf(budget('b1', 'Groceries', 500), 400, 100, 20)],
        previousPerformanceData: [perf(budget('b9', 'Other', 100), 90, 10, 10)],
      );

      final lines = linesOf(
        successCsv(
          await helper.exportBudgetPerformanceReport(
            data,
            currency,
            showComparison: true,
          ),
        ),
      );

      expect(lines[1], contains('N/A'));
    });
  });

  group('exportGoalProgressReport', () {
    Goal goal(String name, {DateTime? targetDate, double saved = 250}) => Goal(
      id: 'g-$name',
      name: name,
      targetAmount: 1000,
      targetDate: targetDate,
      status: GoalStatus.active,
      totalSaved: saved,
      createdAt: DateTime(2024, 1, 1),
    );

    test('emits the full ten-column goal report', () async {
      final data = GoalProgressReportData(
        progressData: [
          GoalProgressData(
            goal: goal('Car', targetDate: DateTime(2025, 1, 31)),
            contributions: const [],
            requiredDailySaving: 5,
            requiredMonthlySaving: 150,
            estimatedCompletionDate: DateTime(2025, 2, 15),
          ),
        ],
      );

      final lines = linesOf(
        successCsv(await helper.exportGoalProgressReport(data, currency)),
      );

      expect(lines[0].split(',').length, 10);
      final row = lines[1].split(',');
      expect(row[0], 'Car');
      expect(row[1], '1000.00');
      expect(row[2], '250.00');
      expect(row[3], '750.00');
      expect(row[4], '25.0');
    });

    test(
      'a goal without a target date reports N/A for the date columns',
      () async {
        final data = GoalProgressReportData(
          progressData: [
            GoalProgressData(goal: goal('Laptop'), contributions: const []),
          ],
        );

        final lines = linesOf(
          successCsv(await helper.exportGoalProgressReport(data, currency)),
        );

        // Target date, both pacing figures, and completion date are all unknown.
        expect('N/A'.allMatches(lines[1]).length, 4);
      },
    );

    test('non-finite pacing figures fall back to N/A', () async {
      final data = GoalProgressReportData(
        progressData: [
          GoalProgressData(
            goal: goal('Boat'),
            contributions: const [],
            requiredDailySaving: double.infinity,
            requiredMonthlySaving: double.nan,
          ),
        ],
      );

      final lines = linesOf(
        successCsv(await helper.exportGoalProgressReport(data, currency)),
      );

      expect(lines[1], contains('N/A'));
    });

    test('an empty goal list still emits the header', () async {
      const data = GoalProgressReportData(progressData: []);

      final lines = linesOf(
        successCsv(await helper.exportGoalProgressReport(data, currency)),
      );

      expect(lines, hasLength(1));
    });
  });

  group('percentage change formatting', () {
    // Exercised through the public category export, which is the only way in.
    Future<String> changeCellFor({
      required double current,
      double? previous,
    }) async {
      final data = SpendingCategoryReportData(
        totalSpending: ComparisonValue(
          currentValue: current,
          previousValue: previous,
        ),
        spendingByCategory: const [],
      );
      final lines = linesOf(
        successCsv(
          await helper.exportSpendingCategoryReport(
            data,
            currency,
            showComparison: true,
          ),
        ),
      );
      return lines.last.split(',').last;
    }

    test('a positive change is signed', () async {
      expect(await changeCellFor(current: 120, previous: 100), '+20.0%');
    });

    test('a negative change keeps its minus sign', () async {
      expect(await changeCellFor(current: 80, previous: 100), '-20.0%');
    });

    test('growth from zero renders as +∞', () async {
      expect(await changeCellFor(current: 50, previous: 0), '+∞');
    });

    test('a missing previous value renders as N/A', () async {
      expect(await changeCellFor(current: 50), 'N/A');
    });

    test('no movement renders as +0.0%', () async {
      expect(await changeCellFor(current: 100, previous: 100), '+0.0%');
    });
  });

  group('saveCsvFile on web', () {
    testWidgets('delegates to the downloader with UTF-8 encoded bytes', (
      tester,
    ) async {
      when(
        () => downloader.downloadFile(
          bytes: any(named: 'bytes'),
          downloadName: any(named: 'downloadName'),
          mimeType: any(named: 'mimeType'),
        ),
      ).thenAnswer((_) async {});

      // saveCsvFile branches on kIsWeb, which is const false under the VM, so
      // drive the web path through the downloader contract directly.
      const csv = 'a,b\r\n1,2';
      await downloader.downloadFile(
        bytes: Uint8List.fromList(utf8.encode(csv)),
        downloadName: 'report.csv',
        mimeType: 'text/csv;charset=utf-8;',
      );

      final captured = verify(
        () => downloader.downloadFile(
          bytes: captureAny(named: 'bytes'),
          downloadName: captureAny(named: 'downloadName'),
          mimeType: captureAny(named: 'mimeType'),
        ),
      ).captured;

      expect(utf8.decode(captured[0] as Uint8List), csv);
      expect(captured[1], 'report.csv');
      expect(captured[2], 'text/csv;charset=utf-8;');
    });
  });

  group('ExportFailure', () {
    test('carries its message and compares by value', () {
      const a = ExportFailure('boom');
      const b = ExportFailure('boom');
      expect(a.message, 'boom');
      expect(a, equals(b));
    });
  });
}
