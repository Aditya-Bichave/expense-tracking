import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';

class AddAuditLog implements UseCase<void, RecurringRuleAuditLog> {
  final RecurringTransactionRepository repository;

  AddAuditLog(this.repository);

  @override
  Future<Either<Failure, void>> call(RecurringRuleAuditLog log) {
    return repository.addAuditLog(log);
  }
}
