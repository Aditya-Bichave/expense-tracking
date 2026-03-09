import 'package:expense_tracker/features/reports/presentation/bloc/income_expense_report/income_expense_report_bloc.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('IncomeExpenseReportEvent', () {
    test('LoadIncomeExpenseReport supports value comparisons', () {
      expect(
        const LoadIncomeExpenseReport(),
        equals(const LoadIncomeExpenseReport()),
      );
      expect(
        const LoadIncomeExpenseReport(
          periodType: IncomeExpensePeriodType.monthly,
          compareToPrevious: true,
        ),
        equals(
          const LoadIncomeExpenseReport(
            periodType: IncomeExpensePeriodType.monthly,
            compareToPrevious: true,
          ),
        ),
      );
      expect(
        const LoadIncomeExpenseReport(
          periodType: IncomeExpensePeriodType.monthly,
        ),
        isNot(
          equals(
            const LoadIncomeExpenseReport(
              periodType: IncomeExpensePeriodType.yearly,
            ),
          ),
        ),
      );
    });

    test('ChangeIncomeExpensePeriod supports value comparisons', () {
      expect(
        const ChangeIncomeExpensePeriod(IncomeExpensePeriodType.monthly),
        equals(
          const ChangeIncomeExpensePeriod(IncomeExpensePeriodType.monthly),
        ),
      );
      expect(
        const ChangeIncomeExpensePeriod(IncomeExpensePeriodType.monthly),
        isNot(
          equals(
            const ChangeIncomeExpensePeriod(IncomeExpensePeriodType.yearly),
          ),
        ),
      );
    });

    test('ToggleIncomeExpenseComparison supports value comparisons', () {
      expect(
        const ToggleIncomeExpenseComparison(),
        equals(const ToggleIncomeExpenseComparison()),
      );
    });
  });
}
