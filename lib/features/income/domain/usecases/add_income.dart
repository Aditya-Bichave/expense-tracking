import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';

class AddIncomeUseCase implements UseCase<Income, AddIncomeParams> {
  final IncomeRepository repository;

  AddIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, Income>> call(AddIncomeParams params) async {
    if (params.income.title.isEmpty ||
        params.income.amount <= 0 ||
        params.income.accountId.isEmpty) {
      return Left(ValidationFailure(
          "Title, positive amount, and account are required."));
    }
    return await repository.addIncome(params.income);
  }
}

class AddIncomeParams extends Equatable {
  final Income income;
  const AddIncomeParams(this.income);
  @override
  List<Object?> get props => [income];
}
