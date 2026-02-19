import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/data/models/income_model.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

class GetIncomesParams extends Equatable {
  final DateTime? startDate;
  final DateTime? endDate;
  final String? categoryId; // Changed to match repository param
  final String? accountId;

  const GetIncomesParams({
    this.startDate,
    this.endDate,
    this.categoryId,
    this.accountId,
  });

  @override
  List<Object?> get props => [startDate, endDate, categoryId, accountId];
}

class GetIncomesUseCase
    implements UseCase<List<IncomeModel>, GetIncomesParams> {
  final IncomeRepository repository;

  GetIncomesUseCase(this.repository);

  @override
  Future<Either<Failure, List<IncomeModel>>> call(
    GetIncomesParams params,
  ) async {
    return await repository.getIncomes(
      startDate: params.startDate,
      endDate: params.endDate,
      categoryId: params.categoryId,
      accountId: params.accountId,
    );
  }
}
