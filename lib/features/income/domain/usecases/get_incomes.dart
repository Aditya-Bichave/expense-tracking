import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

class GetIncomesUseCase implements UseCase<List<Income>, GetIncomesParams> {
  final IncomeRepository repository;

  GetIncomesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Income>>> call(GetIncomesParams params) async {
    log.info(
        "Executing GetIncomesUseCase. Filters: AccID=${params.accountId}, Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");
    try {
      final result = await repository.getIncomes(
        startDate: params.startDate,
        endDate: params.endDate,
        category: params.category,
        accountId: params.accountId,
      );
      result.fold(
        (failure) =>
            log.warning("[GetIncomesUseCase] Failed: ${failure.message}"),
        (incomes) => log.info(
            "[GetIncomesUseCase] Succeeded with ${incomes.length} incomes."),
      );
      return result;
    } catch (e, s) {
      log.severe("[GetIncomesUseCase] Unexpected error$e$s");
      return Left(UnexpectedFailure("Unexpected error getting incomes: $e"));
    }
  }
}

class GetIncomesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? category;
  final String? accountId;

  const GetIncomesParams(
      {this.startDate, this.endDate, this.category, this.accountId});

  @override
  List<Object?> get props => [startDate, endDate, category, accountId];
}
