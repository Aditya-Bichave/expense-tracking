import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_income_expense_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late GetIncomeExpenseReportUseCase usecase;
  late MockReportRepository mockReportRepository;

  setUpAll(() {
    registerFallbackValue(IncomeExpensePeriodType.monthly);
  });

  setUp(() {
    mockReportRepository = MockReportRepository();
    usecase = GetIncomeExpenseReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  const tPeriodType = IncomeExpensePeriodType.monthly;
  final tAccountIds = ['a1'];
  final tReportData = MockIncomeExpenseReportData();

  test(
    'should get income vs expense report from the repository',
    () async {
      // arrange
      when(() => mockReportRepository.getIncomeVsExpense(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            periodType: any(named: 'periodType'),
            accountIds: any(named: 'accountIds'),
          )).thenAnswer((_) async => Right(tReportData));

      // act
      final result = await usecase(GetIncomeExpenseReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
        periodType: tPeriodType,
        accountIds: tAccountIds,
        compareToPrevious: false,
      ));

      // assert
      expect(result, Right(tReportData));
      verify(() => mockReportRepository.getIncomeVsExpense(
            startDate: tStartDate,
            endDate: tEndDate,
            periodType: tPeriodType,
            accountIds: tAccountIds,
          ));
      verifyNoMoreInteractions(mockReportRepository);
    },
  );

  test(
    'should return a failure when the repository fails',
    () async {
      // arrange
      final tFailure = ServerFailure('test error');
      when(() => mockReportRepository.getIncomeVsExpense(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            periodType: any(named: 'periodType'),
            accountIds: any(named: 'accountIds'),
          )).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await usecase(GetIncomeExpenseReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
        periodType: tPeriodType,
        compareToPrevious: false,
      ));

      // assert
      expect(result, Left(tFailure));
      verify(() => mockReportRepository.getIncomeVsExpense(
            startDate: tStartDate,
            endDate: tEndDate,
            periodType: tPeriodType,
            accountIds: null,
          ));
    },
  );
}

class MockIncomeExpenseReportData extends Mock
    implements IncomeExpenseReportData {}
