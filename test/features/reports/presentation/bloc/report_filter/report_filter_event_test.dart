import 'package:expense_tracker/features/reports/presentation/bloc/report_filter/report_filter_bloc.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ReportFilterEvent', () {
    test('LoadFilterOptions supports value comparisons', () {
      expect(
        const LoadFilterOptions(forceReload: true),
        equals(const LoadFilterOptions(forceReload: true)),
      );
      expect(
        const LoadFilterOptions(),
        equals(const LoadFilterOptions(forceReload: false)),
      );
      expect(
        const LoadFilterOptions(forceReload: true),
        isNot(equals(const LoadFilterOptions(forceReload: false))),
      );
    });

    test('UpdateReportFilters supports value comparisons', () {
      final date = DateTime(2023, 1, 1);
      expect(
        UpdateReportFilters(
          startDate: date,
          endDate: date,
          categoryIds: const ['1'],
          transactionType: TransactionType.expense,
        ),
        equals(
          UpdateReportFilters(
            startDate: date,
            endDate: date,
            categoryIds: const ['1'],
            transactionType: TransactionType.expense,
          ),
        ),
      );
      expect(
        UpdateReportFilters(startDate: date),
        isNot(equals(const UpdateReportFilters(categoryIds: ['1']))),
      );
    });

    test('ClearReportFilters supports value comparisons', () {
      expect(const ClearReportFilters(), equals(const ClearReportFilters()));
    });
  });
}
