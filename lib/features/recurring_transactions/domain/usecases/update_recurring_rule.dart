import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rule_by_id.dart';
import 'package:uuid/uuid.dart';

class UpdateRecurringRule implements UseCase<void, RecurringRule> {
  final RecurringTransactionRepository repository;
  final GetRecurringRuleById getRecurringRuleById;
  final AddAuditLog addAuditLog;
  final Uuid uuid;

  UpdateRecurringRule({
    required this.repository,
    required this.getRecurringRuleById,
    required this.addAuditLog,
    required this.uuid,
  });

  @override
  Future<Either<Failure, void>> call(RecurringRule newRule) async {
    final oldRuleOrFailure = await getRecurringRuleById(newRule.id);

    return oldRuleOrFailure.fold(
      (failure) => Left(failure),
      (oldRule) async {
        final logs = _createAuditLogs(oldRule, newRule);
        for (var log in logs) {
          final logResult = await addAuditLog(log);
          if (logResult.isLeft()) {
            return logResult;
          }
        }
        return repository.updateRecurringRule(newRule);
      },
    );
  }

  List<RecurringRuleAuditLog> _createAuditLogs(RecurringRule oldRule, RecurringRule newRule) {
    final List<RecurringRuleAuditLog> logs = [];
    final timestamp = DateTime.now();
    const userId = 'user_id_placeholder'; // TODO: Get actual user ID

    void addLog(String field, dynamic oldValue, dynamic newValue) {
      if (oldValue != newValue) {
        logs.add(RecurringRuleAuditLog(
          id: uuid.v4(),
          ruleId: oldRule.id,
          timestamp: timestamp,
          userId: userId,
          fieldChanged: field,
          oldValue: oldValue.toString(),
          newValue: newValue.toString(),
        ));
      }
    }

    addLog('description', oldRule.description, newRule.description);
    addLog('amount', oldRule.amount, newRule.amount);
    addLog('categoryId', oldRule.categoryId, newRule.categoryId);
    addLog('accountId', oldRule.accountId, newRule.accountId);
    addLog('frequency', oldRule.frequency, newRule.frequency);
    addLog('interval', oldRule.interval, newRule.interval);
    addLog('status', oldRule.status, newRule.status);

    return logs;
  }
}
