import 'package:expense_tracker/core/services/demo_mode_service.dart';
import 'package:expense_tracker/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:expense_tracker/features/transactions/data/models/transaction_model.dart';
import 'package:expense_tracker/main.dart'; // logger

class DemoAwareTransactionDataSource implements TransactionLocalDataSource {
  final HiveTransactionLocalDataSource hiveDataSource;
  final DemoModeService demoModeService;

  DemoAwareTransactionDataSource({
    required this.hiveDataSource,
    required this.demoModeService,
  });

  @override
  Future<TransactionModel> addTransaction(TransactionModel transaction) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareTransactionDS] Adding demo transaction: ${transaction.id}");
      // return demoModeService.addDemoTransaction(transaction);
      throw UnimplementedError();
    } else {
      return hiveDataSource.addTransaction(transaction);
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareTransactionDS] Deleting demo transaction ID: $id");
      // return demoModeService.deleteDemoTransaction(id);
      throw UnimplementedError();
    } else {
      return hiveDataSource.deleteTransaction(id);
    }
  }

  @override
  Future<List<TransactionModel>> getTransactions({String? accountId}) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareTransactionDS] Getting demo transactions.");
      // return demoModeService.getDemoTransactions();
      throw UnimplementedError();
    } else {
      return hiveDataSource.getTransactions(accountId: accountId);
    }
  }

  @override
  Future<TransactionModel> updateTransaction(
      TransactionModel transaction) async {
    if (demoModeService.isDemoActive) {
      log.fine("[DemoAwareTransactionDS] Updating demo transaction: ${transaction.id}");
      // return demoModeService.updateDemoTransaction(transaction);
      throw UnimplementedError();
    } else {
      return hiveDataSource.updateTransaction(transaction);
    }
  }
}
