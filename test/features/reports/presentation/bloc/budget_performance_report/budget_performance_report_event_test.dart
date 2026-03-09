import 'package:expense_tracker/features/reports/presentation/bloc/budget_performance_report/budget_performance_report_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BudgetPerformanceReportEvent', () {
    test('LoadBudgetPerformanceReport supports value comparisons', () {
      expect(
        const LoadBudgetPerformanceReport(
          compareToPrevious: false,
          forceReload: false,
        ),
        equals(
          const LoadBudgetPerformanceReport(
            compareToPrevious: false,
            forceReload: false,
          ),
        ),
      );
      expect(
        const LoadBudgetPerformanceReport(
          compareToPrevious: true,
          forceReload: false,
        ),
        isNot(
          equals(
            const LoadBudgetPerformanceReport(
              compareToPrevious: false,
              forceReload: false,
            ),
          ),
        ),
      );
      expect(
        const LoadBudgetPerformanceReport(
          compareToPrevious: false,
          forceReload: true,
        ),
        isNot(
          equals(
            const LoadBudgetPerformanceReport(
              compareToPrevious: false,
              forceReload: false,
            ),
          ),
        ),
      );
    });

    test('ToggleBudgetComparison supports value comparisons', () {
      expect(
        const ToggleBudgetComparison(),
        equals(const ToggleBudgetComparison()),
      );
    });
  });
}
