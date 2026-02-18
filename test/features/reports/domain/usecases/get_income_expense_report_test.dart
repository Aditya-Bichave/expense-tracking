import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
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
  final tPeriodType = IncomeExpensePeriodType.monthly;
  final tAccountIds = ['account1'];

  final tPeriodData = IncomeExpensePeriodData(
    periodStart: DateTime(2023, 1, 1),
    totalIncome: const ComparisonValue(currentValue: 1000.0),
    totalExpense: const ComparisonValue(currentValue: 500.0),
  );

  final tReportData = IncomeExpenseReportData(
    periodData: [tPeriodData],
    periodType: tPeriodType,
  );

  test('should get income expense report from the repository', () async {
    // arrange
    when(
      () => mockReportRepository.getIncomeVsExpense(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        periodType: any(named: 'periodType'),
        accountIds: any(named: 'accountIds'),
      ),
    ).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(
      GetIncomeExpenseReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
        periodType: tPeriodType,
        accountIds: tAccountIds,
        compareToPrevious: false,
      ),
    );

    // assert
    expect(result, Right(tReportData));
    verify(
      () => mockReportRepository.getIncomeVsExpense(
        startDate: tStartDate,
        endDate: tEndDate,
        periodType: tPeriodType,
        accountIds: tAccountIds,
      ),
    );
    verifyNoMoreInteractions(mockReportRepository);
  });

  test(
    'should return a failure when repository call is unsuccessful',
    () async {
      // arrange
      when(
        () => mockReportRepository.getIncomeVsExpense(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          periodType: any(named: 'periodType'),
          accountIds: any(named: 'accountIds'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await useCase(
        GetIncomeExpenseReportParams(
          startDate: tStartDate,
          endDate: tEndDate,
          periodType: tPeriodType,
          accountIds: tAccountIds,
          compareToPrevious: false,
        ),
      );

      // assert
      expect(result, Left(ServerFailure()));
      verify(
        () => mockReportRepository.getIncomeVsExpense(
          startDate: tStartDate,
          endDate: tEndDate,
          periodType: tPeriodType,
          accountIds: tAccountIds,
        ),
      );
      verifyNoMoreInteractions(mockReportRepository);
    },
  );
}
