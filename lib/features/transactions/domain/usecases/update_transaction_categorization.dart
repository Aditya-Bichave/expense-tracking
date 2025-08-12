import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/categories/domain/entities/categorization_status.dart';
import 'package:expense_tracker/features/expenses/domain/repositories/expense_repository.dart';
import 'package:expense_tracker/features/income/domain/repositories/income_repository.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction_entity.dart';

class UpdateTransactionCategorizationUseCase
    implements UseCase<void, UpdateTransactionCategorizationParams> {
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;

  UpdateTransactionCategorizationUseCase({
    required this.expenseRepository,
    required this.incomeRepository,
  });

  @override
  Future<Either<Failure, void>> call(
      UpdateTransactionCategorizationParams params) async {
    if (params.type == TransactionType.expense) {
      return await expenseRepository.updateExpenseCategorization(
        params.transactionId,
        params.categoryId,
        params.status,
        params.confidenceScore,
      );
    } else {
      return await incomeRepository.updateIncomeCategorization(
        params.transactionId,
        params.categoryId,
        params.status,
        params.confidenceScore,
      );
    }
  }
}

class UpdateTransactionCategorizationParams extends Equatable {
  final String transactionId;
  final String? categoryId;
  final CategorizationStatus status;
  final double? confidenceScore;
  final TransactionType type;

  const UpdateTransactionCategorizationParams({
    required this.transactionId,
    required this.categoryId,
    required this.status,
    required this.confidenceScore,
    required this.type,
  });

  @override
  List<Object?> get props => [
        transactionId,
        categoryId,
        status,
        confidenceScore,
        type,
      ];
}
