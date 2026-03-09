import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncomeExpenseReportState', () {
    test('IncomeExpenseReportInitial supports value comparisons', () {
      expect(
        IncomeExpenseReportInitial(),
        equals(IncomeExpenseReportInitial()),
      );
    });

    test('IncomeExpenseReportLoading supports value comparisons', () {
      expect(
        const IncomeExpenseReportLoading(
          periodType: IncomeExpensePeriodType.monthly,
          compareToPrevious: false,
        ),
        equals(
          const IncomeExpenseReportLoading(
            periodType: IncomeExpensePeriodType.monthly,
            compareToPrevious: false,
          ),
        ),
      );
      expect(
        const IncomeExpenseReportLoading(
          periodType: IncomeExpensePeriodType.monthly,
          compareToPrevious: false,
        ),
        isNot(
          equals(
            const IncomeExpenseReportLoading(
              periodType: IncomeExpensePeriodType.yearly,
              compareToPrevious: false,
            ),
          ),
        ),
      );
    });

    test('IncomeExpenseReportLoaded supports value comparisons', () {
      const data = IncomeExpenseReportData(
        periodData: [],
        periodType: IncomeExpensePeriodType.monthly,
      );
      const data2 = IncomeExpenseReportData(
        periodData: [],
        periodType: IncomeExpensePeriodType.yearly,
      );

      expect(
        const IncomeExpenseReportLoaded(data, showComparison: false),
        equals(const IncomeExpenseReportLoaded(data, showComparison: false)),
      );
      expect(
        const IncomeExpenseReportLoaded(data, showComparison: false),
        isNot(
          equals(const IncomeExpenseReportLoaded(data2, showComparison: false)),
        ),
      );
      expect(
        const IncomeExpenseReportLoaded(data, showComparison: true),
        isNot(
          equals(const IncomeExpenseReportLoaded(data, showComparison: false)),
        ),
      );
    });

    test('IncomeExpenseReportError supports value comparisons', () {
      expect(
        const IncomeExpenseReportError('error'),
        equals(const IncomeExpenseReportError('error')),
      );
      expect(
        const IncomeExpenseReportError('error'),
        isNot(equals(const IncomeExpenseReportError('error2'))),
      );
    });
  });
}
