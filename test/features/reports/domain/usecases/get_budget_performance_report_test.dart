import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_budget_performance_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late GetBudgetPerformanceReportUseCase usecase;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    usecase = GetBudgetPerformanceReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tBudgetIds = ['b1', 'b2'];
  final tAccountIds = ['a1'];

  // We can use a mock or a dummy object. Since the object is complex, we'll Mock it
  // or just assume the repository returns whatever we tell it to return.
  // We don't need to assert the content of the report data here, just that it passes through.
  final tReportData = MockBudgetPerformanceReportData();

  test(
    'should get budget performance report from the repository',
    () async {
      // arrange
      when(() => mockReportRepository.getBudgetPerformance(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            budgetIds: any(named: 'budgetIds'),
            accountIds: any(named: 'accountIds'),
            compareToPrevious: any(named: 'compareToPrevious'),
          )).thenAnswer((_) async => Right(tReportData));

      // act
      final result = await usecase(GetBudgetPerformanceReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
        budgetIds: tBudgetIds,
        accountIds: tAccountIds,
        compareToPrevious: true,
      ));

      // assert
      expect(result, Right(tReportData));
      verify(() => mockReportRepository.getBudgetPerformance(
            startDate: tStartDate,
            endDate: tEndDate,
            budgetIds: tBudgetIds,
            accountIds: tAccountIds,
            compareToPrevious: true,
          ));
      verifyNoMoreInteractions(mockReportRepository);
    },
  );

  test(
    'should return a failure when the repository fails',
    () async {
      // arrange
      final tFailure = ServerFailure('test error');
      when(() => mockReportRepository.getBudgetPerformance(
            startDate: any(named: 'startDate'),
            endDate: any(named: 'endDate'),
            budgetIds: any(named: 'budgetIds'),
            accountIds: any(named: 'accountIds'),
            compareToPrevious: any(named: 'compareToPrevious'),
          )).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await usecase(GetBudgetPerformanceReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
      ));

      // assert
      expect(result, Left(tFailure));
      verify(() => mockReportRepository.getBudgetPerformance(
            startDate: tStartDate,
            endDate: tEndDate,
            budgetIds: null,
            accountIds: null,
            compareToPrevious: false,
          ));
    },
  );
}

class MockBudgetPerformanceReportData extends Mock
    implements BudgetPerformanceReportData {}
