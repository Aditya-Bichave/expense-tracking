// lib/features/budgets/domain/usecases/delete_budget.dart
import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/main.dart';
import 'package:expense_tracker/core/utils/logger.dart';

class DeleteBudgetUseCase implements UseCase<void, DeleteBudgetParams> {
  final BudgetRepository repository;

  DeleteBudgetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteBudgetParams params) async {
    log.info("[DeleteBudgetUseCase] Deleting budget ID: ${params.id}");
    return await repository.deleteBudget(params.id);
  }
}

class DeleteBudgetParams extends Equatable {
  final String id;
  const DeleteBudgetParams({required this.id});
  @override
  List<Object?> get props => [id];
}
