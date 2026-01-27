import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_income_expense_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetIncomeExpenseReportUseCase useCase;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetIncomeExpenseReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetIncomeExpenseReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    periodType: IncomeExpensePeriodType.monthly,
    compareToPrevious: false,
  );

  final tPeriodData = IncomeExpensePeriodData(
    periodStart: tStartDate,
    totalIncome: const ComparisonValue(currentValue: 1000),
    totalExpense: const ComparisonValue(currentValue: 500),
  );

  final tReportData = IncomeExpenseReportData(
    periodData: [tPeriodData],
    periodType: IncomeExpensePeriodType.monthly,
  );

  test('should get income/expense report from the repository', () async {
    // arrange
    when(() => mockReportRepository.getIncomeVsExpense(
          startDate: tStartDate,
          endDate: tEndDate,
          periodType: IncomeExpensePeriodType.monthly,
          accountIds: null,
        )).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Right(tReportData));
    verify(() => mockReportRepository.getIncomeVsExpense(
          startDate: tStartDate,
          endDate: tEndDate,
          periodType: IncomeExpensePeriodType.monthly,
          accountIds: null,
        ));
    verifyNoMoreInteractions(mockReportRepository);
  });
}
