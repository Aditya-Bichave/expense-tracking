import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class AddRecurringRule implements UseCase<void, RecurringRule> {
  final RecurringTransactionRepository repository;

  AddRecurringRule(this.repository);

  @override
  Future<Either<Failure, void>> call(RecurringRule rule) {
    return repository.addRecurringRule(rule);
  }
}
