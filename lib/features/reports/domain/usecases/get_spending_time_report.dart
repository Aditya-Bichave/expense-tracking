// lib/features/reports/domain/usecases/get_spending_time_report.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';
import 'package:expense_tracker/main.dart';

class GetSpendingTimeReportUseCase
    implements UseCase<SpendingTimeReportData, GetSpendingTimeReportParams> {
  final ReportRepository repository;

  GetSpendingTimeReportUseCase(this.repository);

  @override
  Future<Either<Failure, SpendingTimeReportData>> call(
    GetSpendingTimeReportParams params,
  ) async {
    log.info(
      "[GetSpendingTimeReportUseCase] Granularity: ${params.granularity}, Start: ${params.startDate}, End: ${params.endDate}",
    );
    return await repository.getSpendingOverTime(
      startDate: params.startDate,
      endDate: params.endDate,
      granularity: params.granularity,
      accountIds: params.accountIds,
      categoryIds: params.categoryIds,
    );
  }
}

class GetSpendingTimeReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final TimeSeriesGranularity granularity;
  final List<String>? accountIds;
  final List<String>? categoryIds;

  const GetSpendingTimeReportParams({
    required this.startDate,
    required this.endDate,
    required this.granularity,
    this.accountIds,
    this.categoryIds,
    TransactionType? transactionType,
    required bool compareToPrevious,
  });

  @override
  List<Object?> get props => [
    startDate,
    endDate,
    granularity,
    accountIds,
    categoryIds,
  ];
}
