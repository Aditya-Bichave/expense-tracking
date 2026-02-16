import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/services/downloader_service.dart';
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

  group('exportSpendingCategoryReport', () {
    const tCurrency = '\$';
    final tData = SpendingCategoryReportData(
      totalSpending: const ComparisonValue(currentValue: 100.0),
      spendingByCategory: [
        CategorySpendingData(
          categoryId: '1',
          categoryName: 'Food',
          categoryColor: Colors.red,
          totalAmount: const ComparisonValue(currentValue: 60.0),
          percentage: 0.6,
        ),
        CategorySpendingData(
          categoryId: '2',
          categoryName: 'Transport',
          categoryColor: Colors.blue,
          totalAmount: const ComparisonValue(currentValue: 40.0),
          percentage: 0.4,
        ),
      ],
    );

    test('should return correct CSV string on success', () async {
      final result =
          await helper.exportSpendingCategoryReport(tData, tCurrency);

      // Note: CsvExportHelper uses non-standard Either convention:
      // Left(String) is Success (CSV data), Right(Failure) is Error.
      expect(result.isLeft(), true);
      result.fold(
        (csv) {
          final lines = csv.trim().split('\r\n');
          // Expect header + 2 rows + total row = 4 lines
          expect(lines.length, 4);
          expect(lines[0], 'Category,Amount (\$),Percentage');
          expect(lines[1], 'Food,60.00,60.0%');
          expect(lines[2], 'Transport,40.00,40.0%');
          expect(lines[3], 'TOTAL,100.00,100.0%');
        },
        (failure) => fail('Should be Left(String)'),
      );
    });

    test('should handle comparison columns when showComparison is true',
        () async {
      final tDataWithComparison = SpendingCategoryReportData(
        totalSpending:
            const ComparisonValue(currentValue: 100.0, previousValue: 80.0),
        spendingByCategory: [
          CategorySpendingData(
            categoryId: '1',
            categoryName: 'Food',
            categoryColor: Colors.red,
            totalAmount:
                const ComparisonValue(currentValue: 60.0, previousValue: 50.0),
            percentage: 0.6,
          ),
        ],
      );

      final result = await helper.exportSpendingCategoryReport(
        tDataWithComparison,
        tCurrency,
        showComparison: true,
      );

      expect(result.isLeft(), true);
      result.fold(
        (csv) {
          final lines = csv.trim().split('\r\n');
          // Header should have 5 columns
          expect(lines[0],
              'Category,Amount (\$),Percentage,Previous Amount (\$),Change (%)');
          // Row should have 5 columns
          // Change: (60-50)/50 = 20%
          expect(lines[1], 'Food,60.00,60.0%,50.00,+20.0%');
        },
        (failure) => fail('Should be Left(String)'),
      );
    });
  });
}
