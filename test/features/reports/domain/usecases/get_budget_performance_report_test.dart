import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_status.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_budget_performance_report.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetBudgetPerformanceReportUseCase useCase;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetBudgetPerformanceReportUseCase(mockReportRepository);
  });

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tBudgetIds = ['budget1'];
  final tAccountIds = ['account1'];

  final tBudget = Budget(
    id: 'budget1',
    name: 'Groceries',
    targetAmount: 500.0,
    type: BudgetType.categorySpecific,
    period: BudgetPeriodType.recurringMonthly,
    categoryIds: const ['cat1'],
    startDate: DateTime(2023, 1, 1),
    createdAt: DateTime(2023, 1, 1),
  );

  final tPerformanceData = BudgetPerformanceData(
    budget: tBudget,
    actualSpending: const ComparisonValue(currentValue: 250.0),
    varianceAmount: const ComparisonValue(currentValue: 250.0),
    currentVariancePercent: 50.0,
    health: BudgetHealth.thriving,
    statusColor: Colors.green,
  );

  final tReportData = BudgetPerformanceReportData(
    performanceData: [tPerformanceData],
  );

  test('should get budget performance report from the repository', () async {
    // arrange
    when(
      () => mockReportRepository.getBudgetPerformance(
        startDate: any(named: 'startDate'),
        endDate: any(named: 'endDate'),
        budgetIds: any(named: 'budgetIds'),
        accountIds: any(named: 'accountIds'),
        compareToPrevious: any(named: 'compareToPrevious'),
      ),
    ).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(
      GetBudgetPerformanceReportParams(
        startDate: tStartDate,
        endDate: tEndDate,
        budgetIds: tBudgetIds,
        accountIds: tAccountIds,
        compareToPrevious: false,
      ),
    );

    // assert
    expect(result, Right(tReportData));
    verify(
      () => mockReportRepository.getBudgetPerformance(
        startDate: tStartDate,
        endDate: tEndDate,
        budgetIds: tBudgetIds,
        accountIds: tAccountIds,
        compareToPrevious: false,
      ),
    );
    verifyNoMoreInteractions(mockReportRepository);
  });

  test(
    'should return a failure when repository call is unsuccessful',
    () async {
      // arrange
      when(
        () => mockReportRepository.getBudgetPerformance(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          budgetIds: any(named: 'budgetIds'),
          accountIds: any(named: 'accountIds'),
          compareToPrevious: any(named: 'compareToPrevious'),
        ),
      ).thenAnswer((_) async => Left(ServerFailure()));

      // act
      final result = await useCase(
        GetBudgetPerformanceReportParams(
          startDate: tStartDate,
          endDate: tEndDate,
          budgetIds: tBudgetIds,
          accountIds: tAccountIds,
          compareToPrevious: false,
        ),
      );

      // assert
      expect(result, Left(ServerFailure()));
      verify(
        () => mockReportRepository.getBudgetPerformance(
          startDate: tStartDate,
          endDate: tEndDate,
          budgetIds: tBudgetIds,
          accountIds: tAccountIds,
          compareToPrevious: false,
        ),
      );
      verifyNoMoreInteractions(mockReportRepository);
    },
  );
}
