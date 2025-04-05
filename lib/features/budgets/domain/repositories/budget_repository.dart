// lib/features/budgets/domain/repositories/budget_repository.dart
import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/budgets/domain/entities/budget.dart';

abstract class BudgetRepository {
  Future<Either<Failure, List<Budget>>> getBudgets();
  Future<Either<Failure, Budget?>> getBudgetById(String id);
  Future<Either<Failure, Budget>> addBudget(Budget budget);
  Future<Either<Failure, Budget>> updateBudget(Budget budget);
  Future<Either<Failure, void>> deleteBudget(String id);

  /// Calculates the total amount spent towards a specific budget within a given period.
  Future<Either<Failure, double>> calculateAmountSpent({
    required Budget budget,
    required DateTime periodStart,
    required DateTime periodEnd,
  });
}
