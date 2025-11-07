import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';

class UpdateTransferUseCase implements UseCase<Transaction, UpdateTransferParams> {
  final TransactionRepository repository;

  UpdateTransferUseCase(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(UpdateTransferParams params) async {
    return await repository.updateTransaction(params.transaction);
  }
}

class UpdateTransferParams {
  final Transaction transaction;

  UpdateTransferParams(this.transaction);
}
