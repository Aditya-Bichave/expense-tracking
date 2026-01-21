import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/usecases/get_goal_progress_report.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/mock_helpers.dart';

void main() {
  late GetGoalProgressReportUseCase usecase;
  late MockReportRepository mockReportRepository;

  setUp(() {
    mockReportRepository = MockReportRepository();
    usecase = GetGoalProgressReportUseCase(mockReportRepository);
  });

  final tGoalIds = ['g1', 'g2'];
  final tReportData = MockGoalProgressReportData();

  test(
    'should get goal progress report from the repository',
    () async {
      // arrange
      when(() => mockReportRepository.getGoalProgress(
            goalIds: any(named: 'goalIds'),
            calculateComparisonRate: any(named: 'calculateComparisonRate'),
          )).thenAnswer((_) async => Right(tReportData));

      // act
      final result = await usecase(GetGoalProgressReportParams(
        goalIds: tGoalIds,
        calculateComparisonRate: true,
      ));

      // assert
      expect(result, Right(tReportData));
      verify(() => mockReportRepository.getGoalProgress(
            goalIds: tGoalIds,
            calculateComparisonRate: true,
          ));
      verifyNoMoreInteractions(mockReportRepository);
    },
  );

  test(
    'should return a failure when the repository fails',
    () async {
      // arrange
      final tFailure = ServerFailure('test failure');
      when(() => mockReportRepository.getGoalProgress(
            goalIds: any(named: 'goalIds'),
            calculateComparisonRate: any(named: 'calculateComparisonRate'),
          )).thenAnswer((_) async => Left(tFailure));

      // act
      final result = await usecase(const GetGoalProgressReportParams());

      // assert
      expect(result, Left(tFailure));
      verify(() => mockReportRepository.getGoalProgress(
            goalIds: null,
            calculateComparisonRate: false,
          ));
    },
  );
}

class MockGoalProgressReportData extends Mock
    implements GoalProgressReportData {}
