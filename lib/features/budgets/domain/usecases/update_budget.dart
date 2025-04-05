// lib/features/budgets/domain/usecases/update_budget.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/main.dart';

class UpdateBudgetUseCase implements UseCase<Budget, UpdateBudgetParams> {
  final BudgetRepository repository;

  UpdateBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, Budget>> call(UpdateBudgetParams params) async {
    final budget = params.budget;
    log.info(
        "[UpdateBudgetUseCase] Updating budget: ${budget.name} (ID: ${budget.id})");

    // Validation (mirroring AddBudgetUseCase)
    if (budget.name.trim().isEmpty) {
      return const Left(ValidationFailure("Budget name cannot be empty."));
    }
    if (budget.targetAmount <= 0) {
      return const Left(ValidationFailure("Target amount must be positive."));
    }
    if (budget.type == BudgetType.categorySpecific &&
        (budget.categoryIds == null || budget.categoryIds!.isEmpty)) {
      return const Left(
          ValidationFailure("Please select at least one category."));
    }
    if (budget.period == BudgetPeriodType.oneTime &&
        (budget.startDate == null || budget.endDate == null)) {
      return const Left(ValidationFailure(
          "Start and end dates are required for a one-time budget."));
    }
    if (budget.period == BudgetPeriodType.oneTime &&
        budget.startDate != null &&
        budget.endDate != null &&
        budget.endDate!.isBefore(budget.startDate!)) {
      return const Left(
          ValidationFailure("End date cannot be before start date."));
    }

    return await repository.updateBudget(budget);
  }
}

class UpdateBudgetParams extends Equatable {
  final Budget budget; // Pass the full updated budget object
  const UpdateBudgetParams({required this.budget});
  @override
  List<Object?> get props => [budget];
}
