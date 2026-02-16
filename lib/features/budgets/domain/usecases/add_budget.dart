// lib/features/budgets/domain/usecases/add_budget.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget_enums.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:uuid/uuid.dart';

class AddBudgetUseCase implements UseCase<Budget, AddBudgetParams> {
  final BudgetRepository repository;
  final Uuid uuid;

  AddBudgetUseCase(this.repository, this.uuid);

  @override
  Future<Either<Failure, Budget>> call(AddBudgetParams params) async {
    log.info("[AddBudgetUseCase] Adding budget: ${params.name}");

    // Validation
    if (params.name.trim().isEmpty) {
      return const Left(ValidationFailure("Budget name cannot be empty."));
    }
    if (params.targetAmount <= 0) {
      return const Left(ValidationFailure("Target amount must be positive."));
    }
    if (params.type == BudgetType.categorySpecific &&
        (params.categoryIds == null || params.categoryIds!.isEmpty)) {
      return const Left(
        ValidationFailure(
          "Please select at least one category for a category-specific budget.",
        ),
      );
    }
    if (params.period == BudgetPeriodType.oneTime &&
        (params.startDate == null || params.endDate == null)) {
      return const Left(
        ValidationFailure(
          "Start and end dates are required for a one-time budget.",
        ),
      );
    }
    if (params.period == BudgetPeriodType.oneTime &&
        params.startDate != null &&
        params.endDate != null &&
        params.endDate!.isBefore(params.startDate!)) {
      return const Left(
        ValidationFailure("End date cannot be before start date."),
      );
    }

    final newBudget = Budget(
      id: uuid.v4(),
      name: params.name.trim(),
      type: params.type,
      targetAmount: params.targetAmount,
      period: params.period,
      startDate: params.period == BudgetPeriodType.oneTime
          ? params.startDate
          : null,
      endDate: params.period == BudgetPeriodType.oneTime
          ? params.endDate
          : null,
      categoryIds: params.type == BudgetType.categorySpecific
          ? params.categoryIds
          : null,
      notes: params.notes?.trim(),
      createdAt: DateTime.now(),
    );

    return await repository.addBudget(newBudget);
  }
}

class AddBudgetParams extends Equatable {
  final String name;
  final BudgetType type;
  final double targetAmount;
  final BudgetPeriodType period;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? categoryIds;
  final String? notes;

  const AddBudgetParams({
    required this.name,
    required this.type,
    required this.targetAmount,
    required this.period,
    this.startDate,
    this.endDate,
    this.categoryIds,
    this.notes,
  });

  @override
  List<Object?> get props => [
    name,
    type,
    targetAmount,
    period,
    startDate,
    endDate,
    categoryIds,
    notes,
  ];
}
