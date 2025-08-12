import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class GetRecurringRuleById implements UseCase<RecurringRule, String> {
  final RecurringTransactionRepository repository;

  GetRecurringRuleById(this.repository);

  @override
  Future<Either<Failure, RecurringRule>> call(String id) {
    return repository.getRecurringRuleById(id);
  }
}
