import 'package:hive/hive.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/main.dart'; // Import logger

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getTransactions({String? accountId});
  Future<TransactionModel> addTransaction(TransactionModel transaction);
  Future<TransactionModel> updateTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
}

class HiveTransactionLocalDataSource implements TransactionLocalDataSource {
  final Box<TransactionModel> transactionBox;

  HiveTransactionLocalDataSource(this.transactionBox);

  @override
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    try {
      await transactionBox.put(transaction.id, transaction);
      log.info("Added transaction (ID: ${transaction.id}) to Hive.");
      return transaction;
    } catch (e, s) {
      log.severe("Failed to add transaction (ID: ${transaction.id}) to cache$e$s");
      throw CacheFailure('Failed to add transaction: ${e.toString()}');
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    try {
      await transactionBox.delete(id);
      log.info("Deleted transaction (ID: $id) from Hive.");
    } catch (e, s) {
      log.severe("Failed to delete transaction (ID: $id) from cache$e$s");
      throw CacheFailure('Failed to delete transaction: ${e.toString()}');
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions({String? accountId}) async {
    try {
      if (accountId == null) {
        final transactions = transactionBox.values.toList();
        log.info("Retrieved ${transactions.length} transactions from Hive.");
        return transactions;
      } else {
        final transactions = transactionBox.values
            .where((t) => t.fromAccountId == accountId || t.toAccountId == accountId)
            .toList();
        log.info("Retrieved ${transactions.length} transactions for account (ID: $accountId) from Hive.");
        return transactions;
      }
    } catch (e, s) {
      log.severe("Failed to get transactions from cache$e$s");
      throw CacheFailure('Failed to get transactions: ${e.toString()}');
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
      TransactionModel transaction) async {
    try {
      await transactionBox.put(transaction.id, transaction);
      log.info("Updated transaction (ID: ${transaction.id}) in Hive.");
      return transaction;
    } catch (e, s) {
      log.severe("Failed to update transaction (ID: ${transaction.id}) in cache$e$s");
      throw CacheFailure('Failed to update transaction: ${e.toString()}');
    }
  }
}
