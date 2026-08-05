import 'package:expense_tracker/core/constants/hive_constants.dart';
import 'package:expense_tracker/core/error/failure.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_audit_log_model.dart';
import 'package:expense_tracker/features/recurring_transactions/data/models/recurring_rule_model.dart';
import 'package:hive_ce/hive.dart';

abstract class RecurringTransactionLocalDataSource {
  Future<void> addRecurringRule(RecurringRuleModel rule);
  Future<List<RecurringRuleModel>> getRecurringRules();
  Future<RecurringRuleModel> getRecurringRuleById(String id);
  Future<void> updateRecurringRule(RecurringRuleModel rule);
  Future<void> deleteRecurringRule(String id);

  Future<void> addAuditLog(RecurringRuleAuditLogModel log);
  Future<List<RecurringRuleAuditLogModel>> getAuditLogsForRule(String ruleId);
}

class RecurringTransactionLocalDataSourceImpl
    implements RecurringTransactionLocalDataSource {
  final Box<RecurringRuleModel> recurringRuleBox;
  final Box<RecurringRuleAuditLogModel> recurringRuleAuditLogBox;

  RecurringTransactionLocalDataSourceImpl({
    required this.recurringRuleBox,
    required this.recurringRuleAuditLogBox,
  });

  @override
  Future<void> addRecurringRule(RecurringRuleModel rule) async {
    await recurringRuleBox.put(rule.id, rule);
  }

  @override
  Future<List<RecurringRuleModel>> getRecurringRules() async {
    return recurringRuleBox.values.toList();
  }

  @override
  Future<RecurringRuleModel> getRecurringRuleById(String id) async {
    final rule = recurringRuleBox.get(id);
    if (rule == null) {
      throw const NotFoundFailure('Recurring rule not found');
    }
    return rule;
  }

  @override
  Future<void> updateRecurringRule(RecurringRuleModel rule) async {
    await recurringRuleBox.put(rule.id, rule);
  }

  @override
  Future<void> deleteRecurringRule(String id) async {
    await recurringRuleBox.delete(id);
  }

  @override
  Future<void> addAuditLog(RecurringRuleAuditLogModel log) async {
    await recurringRuleAuditLogBox.put(log.id, log);
  }

  @override
  Future<List<RecurringRuleAuditLogModel>> getAuditLogsForRule(
    String ruleId,
  ) async {
    // ⚡ Bolt Performance Optimization
    // Problem: `.where().toList()` creates an intermediate iterable.
    // Solution: Use a list comprehension.
    // Impact: Reduces GC overhead during DB fetches.
    return [
      for (final log in recurringRuleAuditLogBox.values)
        if (log.ruleId == ruleId) log,
    ];
  }
}
