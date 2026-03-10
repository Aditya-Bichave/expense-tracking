import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetPerformanceReportState', () {
    test('BudgetPerformanceReportInitial supports value comparisons', () {
      expect(
        BudgetPerformanceReportInitial(),
        equals(BudgetPerformanceReportInitial()),
      );
    });

    test('BudgetPerformanceReportLoading supports value comparisons', () {
      expect(
        const BudgetPerformanceReportLoading(compareToPrevious: false),
        equals(const BudgetPerformanceReportLoading(compareToPrevious: false)),
      );
      expect(
        const BudgetPerformanceReportLoading(compareToPrevious: false),
        isNot(
          equals(const BudgetPerformanceReportLoading(compareToPrevious: true)),
        ),
      );
    });

    test('BudgetPerformanceReportLoaded supports value comparisons', () {
      const data1 = BudgetPerformanceReportData(performanceData: []);
      const data2 = BudgetPerformanceReportData(performanceData: []);

      expect(
        const BudgetPerformanceReportLoaded(data1, showComparison: false),
        equals(
          const BudgetPerformanceReportLoaded(data2, showComparison: false),
        ),
      );
      expect(
        const BudgetPerformanceReportLoaded(data1, showComparison: false),
        isNot(
          equals(
            const BudgetPerformanceReportLoaded(data1, showComparison: true),
          ),
        ),
      );
    });

    test('BudgetPerformanceReportError supports value comparisons', () {
      expect(
        const BudgetPerformanceReportError('error'),
        equals(const BudgetPerformanceReportError('error')),
      );
      expect(
        const BudgetPerformanceReportError('error'),
        isNot(equals(const BudgetPerformanceReportError('error2'))),
      );
    });
  });
}
