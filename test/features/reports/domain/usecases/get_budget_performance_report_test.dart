import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_budget_performance_report.dart';
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

  const tReportData = BudgetPerformanceReportData(performanceData: []);

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  final tParams = GetBudgetPerformanceReportParams(
    startDate: tStartDate,
    endDate: tEndDate,
    budgetIds: const ['b1'],
    accountIds: const ['a1'],
    compareToPrevious: true,
  );

  test('should get budget performance report from repository', () async {
    // arrange
    when(
      () => mockReportRepository.getBudgetPerformance(
        startDate: tStartDate,
        endDate: tEndDate,
        budgetIds: ['b1'],
        accountIds: ['a1'],
        compareToPrevious: true,
      ),
    ).thenAnswer((_) async => const Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(tReportData));
    verify(
      () => mockReportRepository.getBudgetPerformance(
        startDate: tStartDate,
        endDate: tEndDate,
        budgetIds: ['b1'],
        accountIds: ['a1'],
        compareToPrevious: true,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockReportRepository);
  });
}
