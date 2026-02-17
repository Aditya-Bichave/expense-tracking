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

  const tReportData = GoalProgressReportData(progressData: []);
  const tParams = GetGoalProgressReportParams(
    goalIds: ['g1'],
    calculateComparisonRate: true,
  );

  test('should get goal progress report from repository', () async {
    // arrange
    when(
      () => mockReportRepository.getGoalProgress(
        goalIds: ['g1'],
        calculateComparisonRate: true,
      ),
    ).thenAnswer((_) async => const Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, const Right(tReportData));
    verify(
      () => mockReportRepository.getGoalProgress(
        goalIds: ['g1'],
        calculateComparisonRate: true,
      ),
    ).called(1);
    verifyNoMoreInteractions(mockReportRepository);
  });
}
