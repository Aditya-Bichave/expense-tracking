import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger

class AddIncomeUseCase implements UseCase<Income, AddIncomeParams> {
  final IncomeRepository repository;

  AddIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, Income>> call(AddIncomeParams params) async {
    log.info("Executing AddIncomeUseCase for '${params.income.title}'.");
    if (params.income.title.trim().isEmpty) {
      log.warning("Validation failed: Income title cannot be empty.");
      return const Left(ValidationFailure("Title cannot be empty."));
    }
    if (params.income.amount <= 0) {
      log.warning("Validation failed: Income amount must be positive.");
      return const Left(ValidationFailure("Amount must be positive."));
    }
    if (params.income.accountId.isEmpty) {
      log.warning("Validation failed: Account selection is required.");
      return const Left(ValidationFailure("Please select an account."));
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
