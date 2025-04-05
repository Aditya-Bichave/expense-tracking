// lib/features/budgets/domain/usecases/get_budgets.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';
import 'package:expense_tracker/features/budgets/domain/repositories/budget_repository.dart';
import 'package:expense_tracker/main.dart';

class GetBudgetsUseCase implements UseCase<List<Budget>, NoParams> {
  final BudgetRepository repository;

  GetBudgetsUseCase(this.repository);

  @override
  Future<Either<Failure, List<Budget>>> call(NoParams params) async {
    log.info("[GetBudgetsUseCase] Fetching budgets.");
    return await repository.getBudgets();
  }
}
