import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_goal_progress_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockReportRepository extends Mock implements ReportRepository {}

void main() {
  late GetGoalProgressReportUseCase useCase;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    useCase = GetGoalProgressReportUseCase(mockReportRepository);
  });

  const tGoalIds = ['1', '2'];

  const tReportData = GoalProgressReportData(progressData: []);

  test('should call getGoalProgress from repository', () async {
    // Arrange
    when(() => mockReportRepository.getGoalProgress(
          goalIds: any(named: 'goalIds'),
          calculateComparisonRate: any(named: 'calculateComparisonRate'),
        )).thenAnswer((_) async => const Right(tReportData));

    // Act
    final result = await useCase(const GetGoalProgressReportParams(
      goalIds: tGoalIds,
      calculateComparisonRate: true,
    ));

    // Assert
    expect(result, const Right(tReportData));
    verify(() => mockReportRepository.getGoalProgress(
          goalIds: tGoalIds,
          calculateComparisonRate: true,
        )).called(1);
  });
}
