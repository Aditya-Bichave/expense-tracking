import 'package:expense_tracker/core/services/downloader_service.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/helpers/csv_export_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDownloaderService extends Mock implements DownloaderService {}

void main() {
  late MockDownloaderService mockDownloaderService;
  late CsvExportHelper helper;

  setUp(() {
    mockDownloaderService = MockDownloaderService();
    helper = CsvExportHelper(downloaderService: mockDownloaderService);
  });

  group('exportSpendingCategoryReport', () {
    test('generates correct CSV string without comparison', () async {
      final data = SpendingCategoryReportData(
        totalSpending:
            const ComparisonValue(currentValue: 100.0, previousValue: 80.0),
        spendingByCategory: [
          CategorySpendingData(
            categoryId: 'c1',
            categoryName: 'Food',
            categoryColor: Colors.red,
            totalAmount:
                const ComparisonValue(currentValue: 60.0, previousValue: 50.0),
            percentage: 0.6,
          ),
          CategorySpendingData(
            categoryId: 'c2',
            categoryName: 'Transport',
            categoryColor: Colors.blue,
            totalAmount:
                const ComparisonValue(currentValue: 40.0, previousValue: 30.0),
            percentage: 0.4,
          ),
        ],
      );

      final result = await helper.exportSpendingCategoryReport(data, '\$');

      expect(result.isLeft(), true);
      final csv = result.fold((l) => l, (r) => throw Exception('Expected Left'));

      // Check headers
      // The exact string depends on CsvToListConverter, usually adds CRLF
      expect(csv, contains('Category,Amount (\$),Percentage'));

      // Check rows
      expect(csv, contains('Food,60.00,60.0%'));
      expect(csv, contains('Transport,40.00,40.0%'));
      expect(csv, contains('TOTAL,100.00,100.0%'));
    });

    test('generates correct CSV string with comparison', () async {
      final data = SpendingCategoryReportData(
        totalSpending:
            const ComparisonValue(currentValue: 100.0, previousValue: 80.0),
        spendingByCategory: [
          CategorySpendingData(
            categoryId: 'c1',
            categoryName: 'Food',
            categoryColor: Colors.red,
            totalAmount:
                const ComparisonValue(currentValue: 60.0, previousValue: 50.0),
            percentage: 0.6,
          ),
        ],
      );

      final result = await helper.exportSpendingCategoryReport(data, '\$',
          showComparison: true);

      expect(result.isLeft(), true);
      final csv = result.fold((l) => l, (r) => throw Exception('Expected Left'));

      // Check headers
      expect(csv, contains(
          'Category,Amount (\$),Percentage,Previous Amount (\$),Change (%)'));

      // Check rows
      // 50.00 previous, 60.00 current. Change: (10/50)*100 = 20%
      expect(csv, contains('Food,60.00,60.0%,50.00,+20.0%'));

      // Total
      // 80.00 previous, 100.00 current. Change: (20/80)*100 = 25%
      expect(csv, contains('TOTAL,100.00,100.0%,80.00,+25.0%'));
    });
  });

  group('exportIncomeExpenseReport', () {
    test('generates correct CSV string', () async {
       final data = IncomeExpenseReportData(
        periodType: IncomeExpensePeriodType.monthly,
        periodData: [
           IncomeExpensePeriodData(
             periodStart: DateTime(2023, 1, 1),
             totalIncome: const ComparisonValue(currentValue: 2000.0),
             totalExpense: const ComparisonValue(currentValue: 1000.0),
           )
        ]
       );

       final result = await helper.exportIncomeExpenseReport(data, '\$');

       expect(result.isLeft(), true);
       final csv = result.fold((l) => l, (r) => throw Exception('Expected Left'));

       expect(csv, contains('Period Start,Income (\$),Expense (\$),Net Flow (\$)'));
       expect(csv, contains('2023-Jan,2000.00,1000.00,1000.00'));
    });
  });
}
