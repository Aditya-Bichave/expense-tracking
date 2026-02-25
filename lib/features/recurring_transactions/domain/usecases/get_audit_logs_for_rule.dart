import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class GetAuditLogsForRule
    implements UseCase<List<RecurringRuleAuditLog>, String> {
  final RecurringTransactionRepository repository;

  GetAuditLogsForRule(this.repository);

  @override
  Future<Either<Failure, List<RecurringRuleAuditLog>>> call(String ruleId) {
    return repository.getAuditLogsForRule(ruleId);
  }
}
