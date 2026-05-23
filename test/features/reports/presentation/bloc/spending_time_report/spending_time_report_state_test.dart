import 'package:expense_tracker/features/reports/presentation/bloc/spending_time_report/spending_time_report_bloc.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SpendingTimeReportState', () {
    test('SpendingTimeReportInitial supports value comparisons', () {
      expect(SpendingTimeReportInitial(), SpendingTimeReportInitial());
    });

    test('SpendingTimeReportLoading supports value comparisons', () {
      expect(
        const SpendingTimeReportLoading(
          granularity: TimeSeriesGranularity.daily,
          compareToPrevious: true,
        ),
        const SpendingTimeReportLoading(
          granularity: TimeSeriesGranularity.daily,
          compareToPrevious: true,
        ),
      );
    });

    test('SpendingTimeReportLoaded supports value comparisons', () {
      final data = const SpendingTimeReportData(
        granularity: TimeSeriesGranularity.daily,
        spendingData: [],
      );
      expect(
        SpendingTimeReportLoaded(data, showComparison: true),
        SpendingTimeReportLoaded(data, showComparison: true),
      );
    });

    test('SpendingTimeReportError supports value comparisons', () {
      expect(
        const SpendingTimeReportError('error'),
        const SpendingTimeReportError('error'),
      );
    });
  });
}
