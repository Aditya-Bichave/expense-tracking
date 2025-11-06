import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/use_case/use_case.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';

class AddTransferUseCase extends UseCase<Transaction, AddTransferParams> {
  final TransactionRepository repository;

  AddTransferUseCase(this.repository);

  @override
  Future<Either<Failure, Transaction>> call(AddTransferParams params) async {
    return await repository.addTransaction(params.transaction);
  }
}

class AddTransferParams {
  final Transaction transaction;

  AddTransferParams(this.transaction);
}
