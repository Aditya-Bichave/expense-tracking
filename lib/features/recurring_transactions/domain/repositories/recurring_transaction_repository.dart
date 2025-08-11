import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';

abstract class RecurringTransactionRepository {
  Future<Either<Failure, void>> addRecurringRule(RecurringRule rule);
  Future<Either<Failure, List<RecurringRule>>> getRecurringRules();
  Future<Either<Failure, RecurringRule>> getRecurringRuleById(String id);
  Future<Either<Failure, void>> updateRecurringRule(RecurringRule rule);
  Future<Either<Failure, void>> deleteRecurringRule(String id);

  Future<Either<Failure, void>> addAuditLog(RecurringRuleAuditLog log);
  Future<Either<Failure, List<RecurringRuleAuditLog>>> getAuditLogsForRule(String ruleId);
}
