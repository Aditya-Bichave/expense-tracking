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

    // Register fallback values if needed, though simple types usually work.
    registerFallbackValue(IncomeExpensePeriodType.monthly);
  });

  const tReportData = IncomeExpenseReportData(
    periodData: [],
    periodType: IncomeExpensePeriodType.monthly,
  );

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetIncomeExpenseReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    periodType: IncomeExpensePeriodType.monthly,
    accountIds: const ['a1'],
    compareToPrevious: true,
  );

  test('should get income vs expense report from repository', () async {
    // arrange
    when(
      () => mockReportRepository.getIncomeVsExpense(
        startDate: tStartDate,
        endDate: tEndDate,
        periodType: IncomeExpensePeriodType.monthly,
        accountIds: ['a1'],
      ),
    ).thenAnswer((_) async => const Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(tReportData));
    verify(
      () => mockReportRepository.getIncomeVsExpense(
        startDate: tStartDate,
        endDate: tEndDate,
        periodType: IncomeExpensePeriodType.monthly,
        accountIds: ['a1'],
      ),
    ).called(1);
    verifyNoMoreInteractions(mockReportRepository);
  });
}
