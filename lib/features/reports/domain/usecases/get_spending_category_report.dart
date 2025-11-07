// lib/features/reports/domain/usecases/get_spending_category_report.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/main.dart';

class GetSpendingCategoryReportUseCase
    implements
        UseCase<SpendingCategoryReportData, GetSpendingCategoryReportParams> {
  final ReportRepository repository;

  GetSpendingCategoryReportUseCase(this.repository);

  @override
  Future<Either<Failure, SpendingCategoryReportData>> call(
      GetSpendingCategoryReportParams params) async {
    log.info(
        "[GetSpendingCategoryReportUseCase] Start: ${params.startDate}, End: ${params.endDate}");
    return await repository.getSpendingByCategory(
      startDate: params.startDate,
      endDate: params.endDate,
      accountIds: params.accountIds,
      categoryIds: params.categoryIds,
      transactionType: params.transactionType,
      compareToPrevious: params.compareToPrevious,
    );
  }
}

class GetSpendingCategoryReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final List<String>? accountIds;
  final List<String>? categoryIds;
  final TransactionType? transactionType;
  final bool compareToPrevious;

  const GetSpendingCategoryReportParams({
    required this.startDate,
    required this.endDate,
    this.accountIds,
    this.categoryIds,
    this.transactionType,
    required this.compareToPrevious,
  });

  @override
  List<Object?> get props => [startDate, endDate, accountIds, categoryIds, transactionType, compareToPrevious];
}
