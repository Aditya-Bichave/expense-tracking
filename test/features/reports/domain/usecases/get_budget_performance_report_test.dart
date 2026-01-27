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
  final tParams = GetBudgetPerformanceReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    budgetIds: const ['1'],
  );

  final tBudget = Budget(
    id: '1',
    name: 'Test Budget',
    type: BudgetType.categorySpecific,
    targetAmount: 1000,
    startDate: tStartDate,
    endDate: tEndDate,
    period: BudgetPeriodType.oneTime,
    categoryIds: const ['cat1'],
    createdAt: DateTime.now(),
  );

  final tBudgetPerformanceData = BudgetPerformanceData(
    budget: tBudget,
    actualSpending: const ComparisonValue(currentValue: 500),
    varianceAmount: const ComparisonValue(currentValue: 500),
    currentVariancePercent: 50.0,
    health: BudgetHealth.thriving,
    statusColor: Colors.green,
  );

  final tReportData = BudgetPerformanceReportData(
    performanceData: [tBudgetPerformanceData],
  );

  test('should get budget performance report from the repository', () async {
    // arrange
    when(() => mockReportRepository.getBudgetPerformance(
          startDate: tStartDate,
          endDate: tEndDate,
          budgetIds: ['1'],
          accountIds: null,
          compareToPrevious: false,
        )).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Right(tReportData));
    verify(() => mockReportRepository.getBudgetPerformance(
          startDate: tStartDate,
          endDate: tEndDate,
          budgetIds: ['1'],
          accountIds: null,
          compareToPrevious: false,
        ));
    verifyNoMoreInteractions(mockReportRepository);
  });
}
