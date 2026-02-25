import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/income/domain/entities/income.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/main.dart'; // Import logger
import 'package:expense_tracker/core/utils/logger.dart';

class UpdateIncomeUseCase implements UseCase<Income, UpdateIncomeParams> {
  final IncomeRepository repository;

  UpdateIncomeUseCase(this.repository);

  @override
  Future<Either<Failure, Income>> call(UpdateIncomeParams params) async {
    log.info(
      "Executing UpdateIncomeUseCase for '${params.income.title}' (ID: ${params.income.id}).",
    );
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
    return await repository.updateIncome(params.income);
  }
}

class UpdateIncomeParams extends Equatable {
  final Income income;
  const UpdateIncomeParams(this.income);
  @override
  List<Object?> get props => [income];
}
