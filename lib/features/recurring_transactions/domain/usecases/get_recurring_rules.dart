import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class GetRecurringRules implements UseCase<List<RecurringRule>, NoParams> {
  final RecurringTransactionRepository repository;

  GetRecurringRules(this.repository);

  @override
  Future<Either<Failure, List<RecurringRule>>> call(NoParams params) {
    return repository.getRecurringRules();
  }
}
