// lib/features/reports/domain/usecases/get_budget_performance_report.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class GetBudgetPerformanceReportUseCase
    implements
        UseCase<BudgetPerformanceReportData, GetBudgetPerformanceReportParams> {
  final ReportRepository repository;

  GetBudgetPerformanceReportUseCase(this.repository);

  @override
  Future<Either<Failure, BudgetPerformanceReportData>> call(
    GetBudgetPerformanceReportParams params,
  ) async {
    log.info(
      "[GetBudgetPerformanceReportUseCase] Start: ${params.startDate}, End: ${params.endDate}, Compare: ${params.compareToPrevious}",
    );
    return await repository.getBudgetPerformance(
      startDate: params.startDate,
      endDate: params.endDate,
      budgetIds: params.budgetIds,
      accountIds: params.accountIds, // Pass accountIds
      compareToPrevious: params.compareToPrevious,
    );
  }
}

class GetBudgetPerformanceReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? budgetIds;
  final List<String>? accountIds; // Added accountIds
  final bool compareToPrevious;

  const GetBudgetPerformanceReportParams({
    required this.startDate,
    required this.endDate,
    this.budgetIds,
    this.accountIds, // Added
    this.compareToPrevious = false,
  });

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    budgetIds,
    accountIds,
    compareToPrevious,
  ];
}
