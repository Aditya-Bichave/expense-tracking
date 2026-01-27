import 'package:dartz/dartz.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal.dart';
import 'package:expense_tracker/features/goals/domain/entities/goal_status.dart';
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

  const tParams = GetGoalProgressReportParams(goalIds: ['1']);

  final tGoal = Goal(
    id: '1',
    name: 'Test Goal',
    targetAmount: 1000,
    totalSaved: 500,
    targetDate: DateTime(2023, 12, 31),
    status: GoalStatus.active,
    createdAt: DateTime.now(),
  );

  final tGoalProgressData = GoalProgressData(
    goal: tGoal,
    contributions: const [],
  );

  final tReportData = GoalProgressReportData(
    progressData: [tGoalProgressData],
  );

  test('should get goal progress report from the repository', () async {
    // arrange
    when(() => mockReportRepository.getGoalProgress(
          goalIds: ['1'],
          calculateComparisonRate: false,
        )).thenAnswer((_) async => Right(tReportData));

    // act
    final result = await useCase(tParams);

    // assert
    expect(result, Right(tReportData));
    verify(() => mockReportRepository.getGoalProgress(
          goalIds: ['1'],
          calculateComparisonRate: false,
        ));
    verifyNoMoreInteractions(mockReportRepository);
  });
}
