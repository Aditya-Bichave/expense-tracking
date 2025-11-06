import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/features/transactions/domain/entities/transaction.dart';
import 'package:expense_tracker/features/transactions/domain/repositories/transaction_repository.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;

  TransactionRepositoryImpl({required this.localDataSource});

  @override
  Future<Either<Failure, Transaction>> addTransaction(Transaction transaction) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      final result = await localDataSource.addTransaction(transactionModel);
      return Right(result.toEntity());
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to add transaction: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteTransaction(String id) async {
    try {
      await localDataSource.deleteTransaction(id);
      return const Right(null);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to delete transaction: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<Transaction>>> getTransactions({String? accountId}) async {
    try {
      final transactionModels = await localDataSource.getTransactions(accountId: accountId);
      final transactions = transactionModels.map((model) => model.toEntity()).toList();
      return Right(transactions);
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to get transactions: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Transaction>> updateTransaction(Transaction transaction) async {
    try {
      final transactionModel = TransactionModel.fromEntity(transaction);
      final result = await localDataSource.updateTransaction(transactionModel);
      return Right(result.toEntity());
    } on CacheFailure catch (e) {
      return Left(e);
    } catch (e) {
      return Left(CacheFailure('Failed to update transaction: ${e.toString()}'));
    }
  }
}
