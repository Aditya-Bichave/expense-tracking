import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';

abstract class TransactionRepository {
  Future<Either<Failure, List<Transaction>>> getTransactions({String? accountId});
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction);
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction);
  Future<Either<Failure, void>> deleteTransaction(String id);
}
