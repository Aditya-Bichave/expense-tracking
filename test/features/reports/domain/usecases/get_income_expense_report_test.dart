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

  setUpAll(() {
    registerFallbackValue(IncomeExpensePeriodType.monthly);
  });

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetIncomeExpenseReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  const tPeriodType = IncomeExpensePeriodType.monthly;
  const tAccountIds = ['1', '2'];

  const tReportData = IncomeExpenseReportData(
    periodData: [],
    periodType: tPeriodType,
  );

  test('should call getIncomeVsExpense from repository', () async {
    // Arrange
    when(() => mockReportRepository.getIncomeVsExpense(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          periodType: any(named: 'periodType'),
          accountIds: any(named: 'accountIds'),
        )).thenAnswer((_) async => const Right(tReportData));

    // Act
    final result = await useCase(GetIncomeExpenseReportParams(
      startDate: tStartDate,
      endDate: tEndDate,
      periodType: tPeriodType,
      accountIds: tAccountIds,
      compareToPrevious: false,
    ));

    // Assert
    expect(result, const Right(tReportData));
    verify(() => mockReportRepository.getIncomeVsExpense(
          startDate: tStartDate,
          endDate: tEndDate,
          periodType: tPeriodType,
          accountIds: tAccountIds,
        )).called(1);
  });
}
