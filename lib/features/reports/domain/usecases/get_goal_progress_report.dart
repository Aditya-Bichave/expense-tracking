// lib/features/reports/domain/usecases/get_goal_progress_report.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class GetGoalProgressReportUseCase
    implements UseCase<GoalProgressReportData, GetGoalProgressReportParams> {
  final ReportRepository repository;

  GetGoalProgressReportUseCase(this.repository);

  @override
  Future<Either<Failure, GoalProgressReportData>> call(
    GetGoalProgressReportParams params,
  ) async {
    log.info(
      "[GetGoalProgressReportUseCase] Fetching goal progress. Compare Rate: ${params.calculateComparisonRate}",
    );
    // For now, only fetch current progress. Comparison logic TBD.
    return await repository.getGoalProgress(
      goalIds: params.goalIds,
      calculateComparisonRate: params.calculateComparisonRate,
    );
  }
}

class GetGoalProgressReportParams extends Equatable {
  final List<String>?
  goalIds; // Optional: Filter specific goals (null = all active)
  final bool calculateComparisonRate;

  const GetGoalProgressReportParams({
    this.goalIds,
    this.calculateComparisonRate = false,
  });

  @override
  List<Object?> get props => [goalIds, calculateComparisonRate];
}
