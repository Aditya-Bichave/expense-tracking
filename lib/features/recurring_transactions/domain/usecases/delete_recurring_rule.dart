import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class DeleteRecurringRule implements UseCase<void, String> {
  final RecurringTransactionRepository repository;

  DeleteRecurringRule(this.repository);

  @override
  Future<Either<Failure, void>> call(String id) {
    return repository.deleteRecurringRule(id);
  }
}
