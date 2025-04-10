// lib/features/reports/domain/usecases/get_income_expense_report.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/reports/domain/entities/report_data.dart';
import 'package:expense_tracker/features/reports/domain/repositories/report_repository.dart';
import 'package:expense_tracker/main.dart';

class GetIncomeExpenseReportUseCase
    implements UseCase<IncomeExpenseReportData, GetIncomeExpenseReportParams> {
  final ReportRepository repository;

  GetIncomeExpenseReportUseCase(this.repository);

  @override
  Future<Either<Failure, IncomeExpenseReportData>> call(
      GetIncomeExpenseReportParams params) async {
    log.info(
        "[GetIncomeExpenseReportUseCase] Period: ${params.periodType}, Start: ${params.startDate}, End: ${params.endDate}");
    return await repository.getIncomeVsExpense(
      startDate: params.startDate,
      endDate: params.endDate,
      periodType: params.periodType,
      accountIds: params.accountIds,
    );
  }
}

class GetIncomeExpenseReportParams extends Equatable {
  final DateTime startDate;
  final DateTime endDate;
  final IncomeExpensePeriodType periodType;
  final List<String>? accountIds;

  const GetIncomeExpenseReportParams({
    required this.startDate,
    required this.endDate,
    required this.periodType,
    this.accountIds,
  });

  @override
  List<Object?> get props => [startDate, endDate, periodType, accountIds];
}
