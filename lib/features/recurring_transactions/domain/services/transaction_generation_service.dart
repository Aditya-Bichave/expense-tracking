import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/generate_transactions_on_launch.dart';
import 'package:expense_tracker/main.dart';

class TransactionGenerationService {
  final GenerateTransactionsOnLaunch _generateTransactionsOnLaunch;

  TransactionGenerationService(this._generateTransactionsOnLaunch);

  Future<void> run() async {
    log.info("Checking for recurring transactions to generate...");
    final result = await _generateTransactionsOnLaunch(const NoParams());
    result.fold(
      (failure) => log.severe(
          "Failed to generate recurring transactions: ${failure.message}"),
      (_) => log.info("Recurring transaction check completed successfully."),
    );
  }
}
