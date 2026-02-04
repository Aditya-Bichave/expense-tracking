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

  final tStartDate = DateTime(2023, 1, 1);
  final tEndDate = DateTime(2023, 1, 31);
  const tBudgetIds = ['1', '2'];
  const tAccountIds = ['A', 'B'];

  const tReportData = BudgetPerformanceReportData(performanceData: []);

  test('should call getBudgetPerformance from repository', () async {
    // Arrange
    when(() => mockReportRepository.getBudgetPerformance(
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          budgetIds: any(named: 'budgetIds'),
          accountIds: any(named: 'accountIds'),
          compareToPrevious: any(named: 'compareToPrevious'),
        )).thenAnswer((_) async => const Right(tReportData));

    // Act
    final result = await useCase(GetBudgetPerformanceReportParams(
      startDate: tStartDate,
      endDate: tEndDate,
      budgetIds: tBudgetIds,
      accountIds: tAccountIds,
      compareToPrevious: true,
    ));

    // Assert
    expect(result, const Right(tReportData));
    verify(() => mockReportRepository.getBudgetPerformance(
          startDate: tStartDate,
          endDate: tEndDate,
          budgetIds: tBudgetIds,
          accountIds: tAccountIds,
          compareToPrevious: true,
        )).called(1);
  });
}
