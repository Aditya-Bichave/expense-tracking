import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Import for debugPrint
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

class GetIncomesUseCase implements UseCase<List<Income>, GetIncomesParams> {
  final IncomeRepository repository;

  GetIncomesUseCase(this.repository);

  @override
  Future<Either<Failure, List<Income>>> call(GetIncomesParams params) async {
    debugPrint(
        "[GetIncomesUseCase] Call method executing with params: AccID=${params.accountId}, Start=${params.startDate}, End=${params.endDate}, Cat=${params.category}");
    try {
      final result = await repository.getIncomes(
        startDate: params.startDate,
        endDate: params.endDate,
        category: params.category,
        accountId: params.accountId,
      );
      debugPrint(
          "[GetIncomesUseCase] Repository returned. Result isLeft: ${result.isLeft()}");
      return result;
    } catch (e, s) {
      debugPrint("[GetIncomesUseCase] *** CRITICAL ERROR: $e\n$s");
      return Left(CacheFailure(
          "Unexpected error in GetIncomesUseCase: $e")); // Use base Failure or a specific one
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
