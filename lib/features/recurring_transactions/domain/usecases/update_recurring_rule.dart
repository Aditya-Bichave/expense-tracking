import 'package:dartz/dartz.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:equatable/equatable.dart';
import 'package:expense_tracker/core/usecases/usecase.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/entities/recurring_rule_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/repositories/recurring_transaction_repository.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/add_audit_log.dart';
import 'package:expense_tracker/features/recurring_transactions/domain/usecases/get_recurring_rule_by_id.dart';
import 'package:uuid/uuid.dart';

class UpdateRecurringRuleParams extends Equatable {
  final RecurringRule newRule;
  final String userId;

  const UpdateRecurringRuleParams({
    required this.newRule,
    required this.userId,
  });

  @override
  List<Object?> get props => [newRule, userId];
}

class UpdateRecurringRule implements UseCase<void, UpdateRecurringRuleParams> {
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
  Future<Either<Failure, void>> call(UpdateRecurringRuleParams params) async {
    final newRule = params.newRule;
    final oldRuleOrFailure = await getRecurringRuleById(newRule.id);

    return oldRuleOrFailure.fold((failure) => Left(failure), (oldRule) async {
      final logs = _createAuditLogs(oldRule, newRule, params.userId);
      for (var log in logs) {
        await addAuditLog(log);
      }
      return repository.updateRecurringRule(newRule);
    });
  }

  List<RecurringRuleAuditLog> _createAuditLogs(
    RecurringRule oldRule,
    RecurringRule newRule,
    String userId,
  ) {
    final List<RecurringRuleAuditLog> logs = [];
    final timestamp = DateTime.now();

    void addLog(String field, dynamic oldValue, dynamic newValue) {
      if (oldValue != newValue) {
        logs.add(
          RecurringRuleAuditLog(
            id: uuid.v4(),
            ruleId: oldRule.id,
            timestamp: timestamp,
            userId: userId,
            fieldChanged: field,
            oldValue: oldValue.toString(),
            newValue: newValue.toString(),
          ),
        );
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
